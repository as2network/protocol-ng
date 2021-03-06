pragma solidity <0.6.0;

/*
Gas to deploy: 3.536.741

PaymentCheck status legend:

UNPROCESSED    = 0;
PROCESSING     = 1;
PAID           = 2;
OVER_PAID      = 3;
PARTIALLY_PAID = 4;
*/

import "./Clause.sol";

contract Payment is Clause("payment-clause-notifiers") {
    string public constant CLAUSE_EVENT_TYPE = "payment_check.added";
    string public constant CREATION_EVENT_TYPE = "payment_clause.created";

    struct PaymentCheck {
        string id;
        uint256 status;
        uint256 checkedAt;
        uint256 createdAt;
    }

    struct Reference {
        string id;
        string value;
        uint256 price;
        string[] checks;
    }

    struct Receiver {
        string id;
        string[] references;
    }

    address public as2network;

    string public contractId;
    string public signatureId;
    string public documentId;

    string[] public receiversArray;

    uint256 public startDate;
    uint256 public endDate;
    uint256 public period;

    mapping(string => Receiver) private receivers;
    mapping(string => Reference) private references;
    mapping(string => PaymentCheck) private paymentChecks;

    constructor(
        address userContractAddress,
        address signatureContractAddress,
        string memory id
    ) public {
        contractId = id;
        as2network = msg.sender;

        userContract = AS2networkUserInterface(userContractAddress);
        signatureContract = NotifierInterface(signatureContractAddress);
    }

    modifier as2networkOnly() {
        require(msg.sender == as2network, "Only AS2network account can perform this action");

        _;
    }

    function init(
        string memory signature,
        string memory document,
        uint256 start,
        uint256 end,
        uint256 paymentPeriod
    ) public as2networkOnly {
        endDate = end;
        startDate = start;
        documentId = document;
        period = paymentPeriod;
        signatureId = signature;

        _notifySignature(CREATION_EVENT_TYPE);
    }

    function setReceiver(string memory id) public as2networkOnly {
        _getReceiver(id);
    }

    function setReference(
        string memory receiverId,
        string memory referenceId,
        string memory referenceValue,
        uint256 referencePrice
    ) public as2networkOnly {
        Reference storage newReference = _getReference(receiverId, referenceId);

        newReference.id = referenceId;
        newReference.value = referenceValue;
        newReference.price = referencePrice;
    }

    function addPaymentCheck(
        string memory receiverId,
        string memory referenceId,
        string memory paymentCheckId,
        uint256 status,
        uint256 checkedAt,
        uint256 createdAt
    ) public as2networkOnly {
        Reference storage newReference = _getReference(receiverId, referenceId);

        paymentChecks[paymentCheckId] = PaymentCheck(paymentCheckId, status, checkedAt, createdAt);

        newReference.checks.push(paymentCheckId);

        _notify(CLAUSE_EVENT_TYPE);
    }

    function getReceiversSize() public view returns (uint256) {
        return receiversArray.length;
    }

    // Get paymentCheck if you got the id
    function getPaymentCheckById(string memory paymentCheckId)
        public
        view
        returns (
            string memory id,
            uint256 status,
            uint256 checkedAt,
            uint256 createdAt
        )
    {
        _checkPaymentCheckExistence(paymentCheckId);

        return (
            paymentChecks[paymentCheckId].id,
            paymentChecks[paymentCheckId].status,
            paymentChecks[paymentCheckId].checkedAt,
            paymentChecks[paymentCheckId].createdAt
        );
    }

    // Get paymentCheckID if you want the last one given a referenceId
    function getLastPaymentCheckFromReference(string memory referenceId)
        public
        view
        returns (
            string memory id,
            uint256 status,
            uint256 checkedAt,
            uint256 createdAt
        )
    {
        _checkPaymentCheckFromReferenceExistence(referenceId, references[referenceId].checks.length - 1);

        return
            getPaymentCheckById(
                paymentChecks[references[referenceId].checks[references[referenceId].checks.length - 1]].id
            );
    }

    // Get paymentCheckID if you want to iterate through all
    // the paymentChecks of a reference
    function getPaymentCheckFromReference(string memory referenceId, uint256 index)
        public
        view
        returns (
            string memory id,
            uint256 status,
            uint256 checkedAt,
            uint256 createdAt,
            bool more
        )
    {
        _checkReferenceExistence(referenceId);

        require(index < references[referenceId].checks.length, "Overflowed index");

        bool thereIsMore = false;

        if (references[referenceId].checks.length > index + 1) thereIsMore = true;

        (
            string memory paymentCheckId,
            uint256 paymentCheckStatus,
            uint256 paymentCheckCheckedAt,
            uint256 paymentCheckCreatedAt
        ) = getPaymentCheckById(references[referenceId].checks[index]);

        return (paymentCheckId, paymentCheckStatus, paymentCheckCheckedAt, paymentCheckCreatedAt, thereIsMore);
    }

    // Get how many paymentChecks there are for a reference
    function getPaymentCheckSizeFromReference(string memory referenceId) public view returns (uint256 size) {
        _checkReferenceExistence(referenceId);

        return references[referenceId].checks.length;
    }

    // Get reference if you got the id
    function getReferenceById(string memory referenceId)
        public
        view
        returns (
            string memory id,
            string memory value,
            uint256 price
        )
    {
        _checkReferenceExistence(referenceId);

        return (references[referenceId].id, references[referenceId].value, references[referenceId].price);
    }

    // Get referenceID if you want to iterate through all
    // the references of a receiver
    function getReferenceFromReceiver(string memory receiverId, uint256 index)
        public
        view
        returns (
            string memory id,
            string memory value,
            uint256 price,
            bool more
        )
    {
        _checkReceiverExistence(receiverId);

        require(index < receivers[receiverId].references.length, "Overflowed index");

        bool thereIsMore = false;

        if (receivers[receiverId].references.length > index + 1) thereIsMore = true;

        (string memory referenceId, string memory referenceValue, uint256 referencePrice) =
            getReferenceById(receivers[receiverId].references[index]);

        return (referenceId, referenceValue, referencePrice, thereIsMore);
    }

    // Get references size from receiver
    function getReferenceSizeFromReceiver(string memory receiverId) public view returns (uint256 size) {
        _checkReceiverExistence(receiverId);

        return receivers[receiverId].references.length;
    }

    // Get receiverID by index
    function getReceiverId(uint256 index) public view returns (string memory id, bool more) {
        require(index < receiversArray.length, "Overflowed index");

        bool thereIsMore = false;

        if (receiversArray.length > index + 1) thereIsMore = true;

        return (receiversArray[index], thereIsMore);
    }

    function _getReceiver(string memory id) private returns (Receiver storage) {
        if (bytes(receivers[id].id).length == 0) {
            string[] memory tmpString;

            receivers[id] = Receiver(id, tmpString);

            receiversArray.push(id);
        }

        return receivers[id];
    }

    function _getReference(string memory receiverId, string memory referenceId) private returns (Reference storage) {
        _getReceiver(receiverId);

        if (bytes(references[referenceId].id).length == 0) {
            string[] memory tmpPaymentChecks;

            references[referenceId] = Reference(referenceId, "", 0, tmpPaymentChecks);

            receivers[receiverId].references.push(referenceId);
        }

        return references[referenceId];
    }

    function _checkReferenceExistence(string memory id) private view {
        require(bytes(references[id].id).length != 0, "This reference doesn't exist");
    }

    function _checkReceiverExistence(string memory id) private view {
        require(bytes(receivers[id].id).length != 0, "This receiver doesn't exist");
    }

    function _checkPaymentCheckFromReferenceExistence(string memory referenceId, uint256 index) private view {
        _checkReferenceExistence(referenceId);

        require(bytes(references[referenceId].checks[index]).length != 0, "This payment check doesn't exist");
    }

    function _checkPaymentCheckExistence(string memory id) private view {
        require(bytes(paymentChecks[id].id).length != 0, "This payment check doesn't exist");
    }
}
