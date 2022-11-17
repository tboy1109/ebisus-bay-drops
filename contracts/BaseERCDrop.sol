// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

abstract contract BaseERCDrop is ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Address for address payable;
   
    ERC1155 public memberships;
    ERC20 token;
    mapping(address => uint) balances;

    address public artist;
    uint128 constant public SCALE = 10000;
    uint128 public fee = 2500;

    uint[] internal order;
    function setArtist(address _artist) public onlyOwner {
        artist = _artist;
    }

    function isMember(address _address) public view returns (bool) {
        return memberships.balanceOf(_address, 1) > 0 || memberships.balanceOf(_address, 2) > 0;
    }
    
    function setFee(uint128 _fee) internal {
        fee = _fee;
    }

    function withdrawPayments(address payee) public nonReentrant{
        require (balances[payee] > 0, "not enough funds");

        token.transfer(payee, balances[payee]);
        balances[payee] = 0;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner{
        require (balances[address(this)] > 0, "not enough funds");
        uint balance = balances[address(this)];
        balances[address(this)] = 0;
        token.transfer(msg.sender, balance);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}