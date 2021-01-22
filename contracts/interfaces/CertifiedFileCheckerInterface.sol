pragma solidity <0.6.0;

import "./NotifierInterface.sol";

contract CertifiedFileCheckerInterface is NotifierInterface {
    address public as2network;

    function getFile(string memory fileHash, uint256 index)
        public
        view
        returns (
            string memory id,
            string memory hash,
            uint256 size,
            uint256 createdAt,
            address owner,
            address contract_address,
            bool more
        );
}
