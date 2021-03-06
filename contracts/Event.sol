pragma solidity <0.6.0;

/*
Gas to deploy: 381.267
*/

import "./interfaces/EventInterface.sol";

contract Event is EventInterface {
    string public id;
    string public evenType;
    string public userAgent;

    uint256 public createdAt;

    constructor(
        string memory eventId,
        string memory initType,
        string memory eventUserAgent,
        uint256 eventCreatedAt
    ) public {
        id = eventId;
        eventType = initType;
        userAgent = eventUserAgent;
        createdAt = eventCreatedAt;
    }
}
