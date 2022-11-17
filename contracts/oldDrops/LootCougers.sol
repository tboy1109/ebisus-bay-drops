// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";

contract LootCougers is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 internal memberPrice = 200 ether;
    uint256 internal normalPrice = 250 ether;
    uint256 private MAX_TOKENS = 2222;
    address[] whitelist;
    address private lootContract;
    string baseURI = "ipfs://QmQgrHzH7E3FeuLV6uEr4PVFJbDbF1vUjhHp8i9uhzD1u9/";
    
    constructor(address _memberships, address _artist, address[] memory _whitelist, address _lootContract) ERC721("CROugars", "CROugars") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        whitelist = _whitelist;
        lootContract = _lootContract;
        fee  =1000;
        mintArtist();
    }

    function setUri(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
  
    function addWhiteList(address[] memory _addresses) public onlyOwner {
        uint len = _addresses.length;
        for(uint i = 0; i < len; i ++) {
            whitelist.push(_addresses[i]);
        }        
    }

    function removeWhiteList(address _address) public onlyOwner {
        uint len = whitelist.length;
        for(uint i = 0; i < len; i ++) {
            if (whitelist[i] == _address) {
                delete whitelist[i];
                return;
            }
        }
    }

    function setCost(uint _cost, bool isMember) public onlyOwner {
        if (isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }

    function hasMillionLoot(address _address) internal view returns (bool) {
        uint balance = ERC20(lootContract).balanceOf(_address);
        if (balance >= 1000000) {
            return true;
        }

        return false;
    }

    function isWhiteList(address _address) public view returns (bool) {
        uint len = whitelist.length;
        for(uint i = 0; i < len; i ++) {
            if (whitelist[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function isDiscount(address _address) internal view returns (bool) {
        // check if user is member
        if (isMember(_address)) {
            return true;
        }
        // check if user has million loot
        if (hasMillionLoot(_address)) {
            return true;
        }

        // check if user is whitelist
        if (isWhiteList(_address)) {
            return true;
        }
        return false;
    }

    function mint(uint256 _count) public payable {
        require(_count <= 20, "not mint more than 20");
        uint price;
        bool _isDiscount = isDiscount(msg.sender);

        if(_isDiscount){
            price = memberPrice; 
        } else {
            price = normalPrice; 
        }
        
        uint amountDue = price * _count;
        require(msg.value >= amountDue, "not enough funds");

        uint amountFee = amountDue.mulDiv(fee, SCALE); 

        for(uint i = 0; i < _count; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, amountDue - amountFee);
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));

      return _tokenURI;
    }

   function safeMint(address _to) internal {
        uint256 tokenId;
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        require(tokenId <= MAX_TOKENS, "sold out!");
         
        _safeMint(_to, tokenId);
    }

    function mintArtist() internal {
        for(uint i = 0; i < 14; i++){
            safeMint(artist);
        }
    }
}