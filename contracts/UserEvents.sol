pragma solidity <0.6.0;

/*
Gas to deploy: 1.241.327
*/

import "./interfaces/NotifierInterface.sol";
import "./interfaces/AS2networkUserInterface.sol";

import "./libraries/Utils.sol";

contract UserEvents is NotifierInterface {
    address public as2network;

    AS2networkUserInterface public userContract;

    string private constant USER_EVENTS = "user_events";

    string private constant FILE_CREATED_EVENT = "file.contract.created";
    string private constant EVENT_CREATED_EVENT = "event.contract.created";
    string private constant TIMELOG_ADDED_EVENT = "timelog.added";
    string private constant DOCUMENT_CREATED_EVENT = "document.contract.created";
    string private constant SIGNATURE_CREATED_EVENT = "signature.contract.created";
    string private constant PAYMENT_CHECK_ADDED_EVENT = "payment_check.added";
    string private constant CERTIFICATE_CREATED_EVENT = "certificate.contract.created";
    string private constant CERTIFIED_FILE_CREATED_EVENT = "certified_file.contract.created";
    string private constant CERTIFIED_EMAIL_CREATED_EVENT = "certified_email.contract.created";

    string private constant FILE_NOTIFIERS_KEY = "file-notifiers";
    string private constant EVENT_NOTIFIERS_KEY = "event-notifiers";
    string private constant DOCUMENT_NOTIFIERS_KEY = "document-notifiers";
    string private constant SIGNATURE_NOTIFIERS_KEY = "signature-notifiers";
    string private constant TIMELOGGER_NOTIFIERS_KEY = "timelogger-clause-notifiers";
    string private constant CERTIFICATE_NOTIFIERS_KEY = "certificate-notifiers";
    string private constant PAYMENT_CHECKS_NOTIFIERS_KEY = "payment-clause-notifiers";
    string private constant CERTIFIED_FILE_NOTIFIERS_KEY = "certified-file-notifiers";
    string private constant CERTIFIED_EMAIL_NOTIFIERS_KEY = "certified-email-notifiers";

    string private constant VALIDATED_NOTIFIERS_KEY = "validated-notifiers";

    event SignatureCreated(address);
    event DocumentCreated(address);
    event FileCreated(address);
    event EventCreated(address);
    event CertifiedFileCreated(address);
    event CertifiedEmailCreated(address);
    event CertificateCreated(address);
    event TimeLogAdded(address);
    event PaymentCheckAdded(address);

    constructor(address as2networkUser) public {
        as2network = msg.sender;

        userContract = AS2networkUserInterface(as2networkUser);

        userContract.setAddressAttribute(USER_EVENTS, address(this));

        userContract.setAddressArrayAttribute(FILE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(EVENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(DOCUMENT_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(SIGNATURE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(TIMELOGGER_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFICATE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_FILE_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(PAYMENT_CHECKS_NOTIFIERS_KEY, address(this));
        userContract.setAddressArrayAttribute(CERTIFIED_EMAIL_NOTIFIERS_KEY, address(this));
    }

    function notify(string memory eventType, address addr) public {
        bytes32 bytes32event = Utils.keccak(eventType);

        require(validAddress(), "Only AS2network or a validated account can perform this action");

        if (bytes32event == Utils.keccak(SIGNATURE_CREATED_EVENT)) {
            emit SignatureCreated(addr);
        } else if (bytes32event == Utils.keccak(DOCUMENT_CREATED_EVENT)) {
            emit DocumentCreated(addr);
        } else if (bytes32event == Utils.keccak(FILE_CREATED_EVENT)) {
            emit FileCreated(addr);
        } else if (bytes32event == Utils.keccak(EVENT_CREATED_EVENT)) {
            emit EventCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFIED_FILE_CREATED_EVENT)) {
            emit CertifiedFileCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFIED_EMAIL_CREATED_EVENT)) {
            emit CertifiedEmailCreated(addr);
        } else if (bytes32event == Utils.keccak(CERTIFICATE_CREATED_EVENT)) {
            emit CertificateCreated(addr);
        } else if (bytes32event == Utils.keccak(TIMELOG_ADDED_EVENT)) {
            emit TimeLogAdded(addr);
        } else if (bytes32event == Utils.keccak(PAYMENT_CHECK_ADDED_EVENT)) {
            emit PaymentCheckAdded(addr);
        }
    }

    function validAddress() internal view returns (bool) {
        address checkedAddress;
        uint256 notificationIndex = 0;
        bool result = false;

        if (tx.origin == as2network) {
            result = true;
        } else {
            do {
                checkedAddress = userContract.getAddressArrayAttribute(VALIDATED_NOTIFIERS_KEY, notificationIndex);

                if (checkedAddress == tx.origin) {
                    result = true;

                    checkedAddress = address(0);
                }

                ++notificationIndex;
            } while (checkedAddress != address(0));
        }

        return result;
    }
}
