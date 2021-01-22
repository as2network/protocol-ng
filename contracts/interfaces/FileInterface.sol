pragma solidity <0.6.0;

contract FileInterface {
    address public parent;

    string public id;
    string public name;
    string public originalFileHash;

    uint256 public createdAt;
    uint256 public size;

    function init(
        string memory fileName,
        string memory fileHash,
        uint256 fileDate,
        uint256 fileSize
    ) public;
}
