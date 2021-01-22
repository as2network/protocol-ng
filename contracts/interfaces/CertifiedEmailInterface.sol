pragma solidity <0.6.0;

import "./AS2networkUserInterface.sol";
import "./CertificateInterface.sol";
import "./EventInterface.sol";

contract CertifiedEmailInterface {
    address public as2network;
    address public deployer;
    address public owner;

    string public id;
    string public subjectHash;
    string public bodyHash;
    string public deliveryType;

    string[] public certificatesId;

    uint256 public createdAt;

    AS2networkUserInterface public userSmartContract;

    mapping(string => CertificateInterface) private certificates;

    function notifyCreation() public;

    function createCertificate(
        string memory certificateId,
        uint256 certificateCreatedAt,
        address certificateOwner
    ) public;

    function createEvent(
        string memory certificateId,
        string memory eventId,
        string memory eventType,
        string memory eventUserAgent,
        uint256 eventCreatedAt
    ) public;

    function createFile(
        string memory certificateId,
        string memory fileHash,
        string memory fileId,
        string memory fileName,
        uint256 fileCreatedAt,
        uint256 fileSize
    ) public;

    function getCertificate(string memory certificateId) public view returns (address);

    function getEvent(string memory certificateId, string memory eventId) public view returns (address);

    function getFile(string memory certificateId) public view returns (address);

    function getCertificatesSize() public view returns (uint256);

    function notifyEntityEvent(
        string memory notifiersKey,
        string memory createdEvent,
        address adrToNotify
    ) public;

    function _certificateExist(string memory certificateId) private view returns (bool);

    function _getCertificate(string memory certificateId) private returns (CertificateInterface);
}
