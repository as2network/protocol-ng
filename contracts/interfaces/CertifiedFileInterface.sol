pragma solidity <0.6.0;

import "./AS2networkUserInterface.sol";
import "./CertifiedFileCheckerInterface.sol";

contract CertifiedFileInterface {
    address public as2network;
    address public owner;

    string public id;
    string public hash;

    uint public createdAt;
    uint public size;

    AS2networkUserInterface userContract;
}
