pragma solidity <0.6.0;

import "./FileInterface.sol";
import "./EventInterface.sol";

contract DocumentInterface {
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

    mapping(string => EventInterface) private events;

    function init(string memory initType, uint256 documentCreatedAt) public;

    function setSignatureOwner(address signatureOwnerAdr) public;

    function setOwner(address signerAddress) public;

    function sign(uint256 documentSignedAt) public;

    function notifyEntityEvent(
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    ) internal;

    function decline(string memory documentDeclineReason) public;

    function cancel(string memory documentCancelReason) public;

    function createFile(
        string memory fileId,
        string memory fileName,
        string memory fileHash,
        uint256 fileCreatedAt,
        uint256 fileSize
    ) public;

    function setFileHash(string memory fileHash) public;

    function createEvent(
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint256 eventCreatedAt
    ) public;

    function getEvent(string memory eventId) public view returns (address);

    function getEventsSize() public view returns (uint256);
}
