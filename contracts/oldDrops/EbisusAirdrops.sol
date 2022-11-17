// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../SafeMathLite.sol";

contract EbisusAirdrops is ERC1155, Ownable {
    using SafeMathLite for uint256;

    mapping(uint256 => string) uris;
    mapping(uint256 => uint) limits;
    mapping(uint256 => uint) balances;
    uint256[] tokenIds;

    constructor() ERC1155("") {
    }

    function setLimit(uint256 _tokenId, uint256 _amount) external onlyOwner {
        require(limits[_tokenId] == 0, "can't modify the limit");

        limits[_tokenId] = _amount;
    }

    function getLimit(uint256 _tokenId) external view onlyOwner returns(uint256) {
        return limits[_tokenId];
    }

    function setUri(uint256 _tokenId, string memory _uri) external onlyOwner {
        bytes memory tokenURI = bytes(uris[_tokenId]);
        if (tokenURI.length == 0) {
            tokenIds.push(_tokenId);
        }
        uris[_tokenId] = _uri;
    }

    function getAllKnownTokenIds() external view returns(uint256[] memory) {
        return tokenIds;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return uris[_tokenId];
    }

    function mintAirdrop(uint256 _tokenId, address[] calldata _addresses) external {
        bytes memory tokenURI = bytes(uris[_tokenId]);
        require(tokenURI.length != 0, "unknown tokenId");
        
        uint256 len = _addresses.length;

        balances[_tokenId] = balances[_tokenId].add(limits[_tokenId]);

        require(balances[_tokenId] <= limits[_tokenId], "can't mint more than limit");

        for (uint256 i = 0; i < len; i ++) {
            _mint(_addresses[i], _tokenId, 1, "");
        }
    }
}