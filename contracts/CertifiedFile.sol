pragma solidity <0.6.0;

/*
Gas to deploy: 747.382
*/

import "./interfaces/CertifiedFileInterface.sol";
import "./interfaces/AS2networkUserInterface.sol";


contract CertifiedFile is CertifiedFileInterface {
    address public as2network;
    address public owner;

    string constant private CREATED_EVENT = "certified_file.contract.created";
    string constant private NOTIFIERS_KEY = "certified-file-notifiers";

    string public id;
    string public hash;

    uint public createdAt;
    uint public size;

    AS2networkUserInterface public userContract;

    modifier as2networkOnly() {
        require(
            msg.sender == as2network,
            "Only AS2network account can perform this action"
        );

        _;
    }

    constructor(
        address _owner,
        address userContractAddress,
        string memory fileId,
        string memory fileHash,
        uint fileCreatedAt,
        uint fileSize
    )
        public
    {
        as2network = msg.sender;
        owner = _owner;

        id = fileId;
        hash = fileHash;
        size = fileSize;
        createdAt = fileCreatedAt;

        userContract = AS2networkUserInterface(userContractAddress);
    }

    function notifyEvent ()
        public
        as2networkOnly
    {
        address contractToNofify;
        uint notificationIndex = 0;

        do {
            contractToNofify = userContract.getAddressArrayAttribute(NOTIFIERS_KEY, notificationIndex);
            ++notificationIndex;

            if (contractToNofify != address(0)) {
                contractToNofify.call(
                    abi.encodeWithSignature(
                        "notify(string,address)",
                        CREATED_EVENT,
                        address(this)
                    )
                );
            }
        } while (contractToNofify != address(0));
    }
}
