// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";

contract Deplone is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 internal memberPrice = 250 ether;
    uint256 internal normalPrice = 300 ether;
    uint256 private MAX_TOKENS = 22;
    string baseURI = "ipfs://QmPCdD65AHRpVMuw6Zc2knd8NC36dvVPAA7reNFpt5vgVP/";
    
    constructor(address _memberships, address _artist, uint16[] memory _order) ERC721("Admiration", "ADMIRE") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        order = _order;
        fee = 500;
    }
   
    function setCost(uint _cost, bool isMember) public onlyOwner {
        if (isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }

    function mint(uint256 _count) public payable {
        require(_count == 1, "not mint more than one");
        uint price;
        bool _isMember = isMember(msg.sender);

        if(_isMember){
            price = memberPrice; 
        } else {
            price = normalPrice; 
        }
        
        require(msg.value >= price, "not enough funds");

        uint amountFee = price.mulDiv(fee, SCALE); 

        for(uint i = 0; i < _count; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, price - amountFee);
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));

      return _tokenURI;
    }

   function safeMint(address _to) internal {
        uint256 tokenId;
        
        tokenId = _tokenIdCounter.current();

        require(tokenId < MAX_TOKENS, "sold out!");
        _tokenIdCounter.increment();
         
        _safeMint(_to, order[tokenId]);
    }
}