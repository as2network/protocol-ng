pragma solidity <0.6.0;

import "./AS2networkUserInterface.sol";
import "./CertifiedFileCheckerInterface.sol";

contract CertifiedFileInterface {
    address public as2network;
    address public owner;

    string public id;
    string public hash;

    uint256 public createdAt;
    uint256 public size;

    AS2networkUserInterface userContract;
}
