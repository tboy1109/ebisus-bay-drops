// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Market {
    function isMember(address user) public view virtual returns (bool);
    function addToEscrow(address _address) external virtual payable;
}
abstract contract BaseDrop is ERC721Enumerable, Ownable, PullPayment, Pausable, ReentrancyGuard {
    using Address for address payable;
   
    address public artist;
    uint128 constant internal SCALE = 10000;
    uint128 internal fee = 2500;
    uint16[] internal order;
    address public marketContract;

    function isMember(address _address) public view returns (bool) {
        return Market(marketContract).isMember(_address);
    }

    function payDirect(uint256 amount) internal {
        Market(marketContract).addToEscrow{value: amount}(artist);
    }

    function withdrawPayments(address payable payee) public virtual override nonReentrant{
        super.withdrawPayments(payee);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public virtual onlyOwner{
        payable(msg.sender).sendValue(address(this).balance);
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }
}