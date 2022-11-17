// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";

contract LazyHorse2 is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private MAX_TOKENS = 10000;
    uint256 internal memberPrice = 275 ether;
    uint256 internal normalPrice = 300 ether;
    bool revealed = false;
    string baseURI=  "https://www.lazyhorseraceclub.com/lhrcmetadata/";

    constructor(address _memberships, address _artist) ERC721("Lazy Horse Member NFT", "PONY") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        fee = 1000;
        _tokenIdCounter._value = 2000;
    }
    function cost() public view returns (uint) {
        return normalPrice;
    }
    function memberCost() public view returns (uint) {
        return memberPrice;
    }
    function setMaxToken(uint256 _maxTokens) public onlyOwner {
        MAX_TOKENS = _maxTokens;
    }
    function setCost(uint _cost, bool _isMember) public onlyOwner {
        if (_isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }
    function setBaseUri(string calldata _uri) public onlyOwner {
        baseURI = _uri;
    }
    function mint(uint256 _count) public payable {
        uint price;
        bool _isMember = isMember(msg.sender);

        if(_isMember){
            price = memberPrice; // 275 ether
        } else {
            price = normalPrice; // 300 ether
        }
        
        uint amountDue = price * _count;
        require(msg.value >= amountDue, "not enough funds");

        uint amountFee = amountDue.mulDiv(fee, SCALE); 

        for(uint i = 0; i < _count; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, amountDue - amountFee);
    }
    function mintForDeployer(uint256 count) public onlyOwner {
        for (uint i = 0; i < count; i ++) {
            safeMint(artist);
        }
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory uri = string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));

      return uri;
    }
   function safeMint(address _to) internal {
        uint256 tokenId;
        _tokenIdCounter.increment();        
        tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_TOKENS, "sold out!");

        _safeMint(_to, tokenId);
    }
}