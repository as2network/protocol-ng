pragma solidity <0.6.0;

import "./DocumentInterface.sol";
import "./AS2networkUserInterface.sol";

contract SignatureInterface {
    address public as2network;
    address public deployer;
    address public owner;

    string public id;

    string[] public documentsId;

    int256 public createdAt;

    mapping(string => DocumentInterface) private documents;

    mapping(string => address) private clauses;

    AS2networkUserInterface public userContract;

    function notify(string memory attribute, address adr) public;

    function notifyCreation() public;

    function createDocument(
        string memory documentId,
        string memory signatureType,
        uint256 documentCreatedAt
    ) public;

    function setDocumentOwner(string memory documentId, address documentOwner) public;

    function setSignedFileHash(string memory documentId, string memory signedFileHash) public;

    function cancelDocument(string memory documentId, string memory cancelReason) public;

    function createFile(
        string memory documentId,
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint256 fileCreatedAt,
        uint256 fileSize
    ) public;

    function createEvent(
        string memory documentId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint256 eventCreatedAt
    ) public;

    function getClause(string memory clauseType) public view returns (address clauseAddress);

    function getFile(string memory documentId) public view returns (address);

    function getDocument(string memory documentId) public view returns (address);

    function getDocumentByIndex(uint256 index) public view returns (address);

    function getDocumentsSize() public view returns (uint256);

    function getEvent(string memory documentId, string memory eventId) public view returns (address);

    function _notifyEntityEvent(
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    ) private;

    function _getDocument(string memory documentId) private returns (DocumentInterface);

    function _documentExist(string memory documentId) private view returns (bool);
}
