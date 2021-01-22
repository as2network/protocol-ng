pragma solidity <0.6.0;

import "./interfaces/AS2networkUserInterface.sol";


contract BaseAggregator {
    AS2networkUserInterface public userContract;

    address public as2network;

    string public aggregatorName;
    string public notifiersKey;

    modifier as2networkOnly () {
        require(
            tx.origin == as2network,
            "Only AS2network account can perform this action"
        );

        _;
    }

    constructor(
        address userContractAddress,
        string memory aggregatorString,
        string memory notifiersString
    ) public {
        as2network = msg.sender;

        aggregatorName = aggregatorString;
        notifiersKey = notifiersString;

        userContract = AS2networkUserInterface(userContractAddress);

        userContract.setAddressAttribute(
            aggregatorName,
            address(this)
        );

        userContract.setAddressArrayAttribute(
            notifiersKey,
            address(this)
        );
    }
}
