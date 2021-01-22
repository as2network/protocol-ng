pragma solidity <0.6.0;

/*
Gas to deploy: 2.094.931
*/

import "./interfaces/DocumentInterface.sol";
import "./interfaces/FileInterface.sol";
import "./interfaces/EventInterface.sol";
import "./interfaces/AS2networkUserInterface.sol";
import "./libraries/Utils.sol";

contract Document is DocumentInterface {
    string private constant FILE_CREATED_EVENT = "file.contract.created";
    string private constant EVENT_CREATED_EVENT = "event.contract.created";

    string private constant ID_DOCUMENT_SIGNED = "id_document_signed";
    string private constant ID_FILE_SIGNED_HASH = "id_file_signed_hash";
    string private constant ID_DOCUMENT_DECLINED = "id_document_declined";
    string private constant ID_DOCUMENT_CANCELED = "id_document_canceled";

    string private constant DOCUMENT_SIGNED_EVENT = "document.contract.signed";
    string private constant FILE_SIGNED_HASH_EVENT = "file.signed_hash.created";
    string private constant DOCUMENT_DECLINED_EVENT = "document.contract.declined";
    string private constant DOCUMENT_CANCELED_EVENT = "document.contract.canceled";

    string private constant DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string private constant FILE_NOTIFIERS_KEY = "file-notifiers";
    string private constant EVENT_NOTIFIERS_KEY = "event-notifiers";

    address public signature;
    address public signer;
    address public deployer;

    string public id;
    string public cancelReason;
    string public signatureType;
    string public declineReason;
    string public signedFileHash;

    string[] public eventsId;

    uint256 public signedAt;
    uint256 public createdAt;

    bool public signed;
    bool public canceled;
    bool public declined;

    FileInterface public file;

    AS2networkUserInterface public signatureOwner;

    mapping(string => EventInterface) private events;

    constructor(string memory documentId, address signatureDeployer) public {
        signature = msg.sender;
        deployer = signatureDeployer;
        id = documentId;
    }

    modifier protected() {
        require(msg.sender == signature || msg.sender == signer, "Only the Signature account can perform this action");

        _;
    }

    modifier signerOnly() {
        require(msg.sender == signer, "Only the owner account can perform this action");

        _;
    }

    function init(string memory initType, uint256 documentCreatedAt) public protected {
        signatureType = initType;
        createdAt = documentCreatedAt;
    }

    function setSignatureOwner(address signatureOwnerAdr) public protected {
        signatureOwner = AS2networkUserInterface(signatureOwnerAdr);
    }

    function setOwner(address signerAddress) public protected {
        signer = signerAddress;
    }

    function sign(uint256 documentSignedAt) public signerOnly {
        require(!declined || !canceled, "Document is already declined or canceled, you can't sign it");

        signedAt = documentSignedAt;

        signed = true;

        createEvent(ID_DOCUMENT_SIGNED, DOCUMENT_SIGNED_EVENT, "solidity", block.timestamp);
    }

    function decline(string memory documentDeclineReason) public signerOnly {
        require(!signed, "Document is already signed, you can't decline it");

        declineReason = documentDeclineReason;

        declined = true;

        createEvent(ID_DOCUMENT_DECLINED, DOCUMENT_DECLINED_EVENT, "Solidity", block.timestamp);
    }

    function cancel(string memory documentCancelReason) public protected {
        require(!signed, "Document is already signed, you can't cancel it");

        cancelReason = documentCancelReason;

        canceled = true;

        createEvent(ID_DOCUMENT_CANCELED, DOCUMENT_CANCELED_EVENT, "solidity", block.timestamp);
    }

    function createFile(
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint256 fileCreatedAt,
        uint256 fileSize
    ) public protected {
        (bool success, bytes memory returnData) =
            deployer.delegatecall(abi.encodeWithSignature("deployFile(string)", fileId));

        require(success, "Error while deploying file from document");

        file = FileInterface(Utils._bytesToAddress(returnData));

        file.init(fileName, fileHash, fileCreatedAt, fileSize);

        notifyEntityEvent(FILE_NOTIFIERS_KEY, FILE_CREATED_EVENT, address(file));
    }

    function setFileHash(string memory fileHash) public protected {
        signedFileHash = fileHash;

        createEvent(ID_FILE_SIGNED_HASH, FILE_SIGNED_HASH_EVENT, "solidity", block.timestamp);
    }

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint256 eventCreatedAt
    ) public protected {
        (bool success, bytes memory returnData) =
            deployer.delegatecall(
                abi.encodeWithSignature(
                    "deployEvent(string,string,string,uint256)",
                    eventId,
                    eventType,
                    eventUserAgent,
                    eventCreatedAt
                )
            );

        require(success, "Error while deploying event from document");

        events[eventId] = EventInterface(Utils._bytesToAddress(returnData));

        eventsId.push(eventId);

        notifyEntityEvent(EVENT_NOTIFIERS_KEY, EVENT_CREATED_EVENT, address(events[eventId]));
    }

    function notifyEntityEvent(
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    ) internal {
        address contractToNofify;
        uint256 notificationIndex = 0;

        do {
            contractToNofify = signatureOwner.getAddressArrayAttribute(notifiersKey, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(abi.encodeWithSignature("notify(string,address)", createdEvent, adrToNotify));
            }
        } while (contractToNofify != address(0));
    }

    function getEvent(string memory eventId) public view returns (address) {
        require(address(events[eventId]) != address(0), "The event doesn't exist");

        return address(events[eventId]);
    }

    function getEventsSize() public view returns (uint256) {
        return eventsId.length;
    }
}
