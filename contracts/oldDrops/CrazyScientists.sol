// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../interfaces/IDrop.sol";

struct Info {
    uint256 regularCost;
    uint256 memberCost;
    uint256 whitelistCost;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 maxMintPerAddress;
    uint256 maxMintPerTx;
}

contract CrazyScientists is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private whitelistCost = 329 ether;
    uint256 private memberCost = 329 ether;
    uint256 private regularCost = 379 ether;
    uint64 constant MAX_TOKENS = 5555;
    uint8 constant MAX_MINTAMOUNT = 5;
    uint8 private currentChunkIndex;
    mapping(address => bool) whitelist;
    string baseURI = "ipfs://QmWFKmEm9bU2dUqyk7QAHwf2WuG4kX1h4VyijeYKrBhduv";
    
    constructor(address _memberships, address _artist) ERC721("Crazy Scientists", "SCIENTIST") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        fee = 1000;
    }

    function getLen() public view returns(uint) {
        return order.length;
    }
    
    function setSequnceChunk(uint8 _chunkIndex, uint16[] memory _chunk) public onlyOwner {
        require(currentChunkIndex <= _chunkIndex, "chunkIndex exists");
        if (_chunkIndex == 0) {
            order = _chunk;
            mintForArtist();
        } else {
            uint len = _chunk.length;
            for(uint i = 0; i < len; i ++) {
                order.push(_chunk[i]);
            }
        }
        currentChunkIndex = _chunkIndex + 1;
    }

    function addWhiteList(address[] memory _addresses) public onlyOwner {
        uint len = _addresses.length;
        for(uint i = 0; i < len; i ++) {
            whitelist[_addresses[i]] = true;
        }        
    }

    function getInfo() external override view returns (Info memory) {
        Info memory allInfo;
        allInfo.regularCost = regularCost;
        allInfo.memberCost = memberCost;
        allInfo.whitelistCost = whitelistCost;
        allInfo.maxSupply = MAX_TOKENS;
        allInfo.totalSupply = super.totalSupply();
        allInfo.maxMintPerTx = MAX_MINTAMOUNT;

        return allInfo;
    }

    function removeWhiteList(address _address) public onlyOwner {
        if (whitelist[_address]) {
            delete whitelist[_address];
        }
    }

    function mintCost(address _minter) external override view returns(uint256) {
        if (isWhiteList(_minter)) {
            return whitelistCost;
        } else if (isMember(_minter)) {
            return memberCost;
        } else {
            return regularCost;
        }
    }
    
    function setCost(uint256 _cost, bool isMember) external onlyOwner {
        if (isMember) {
            memberCost = _cost;
        } else {
            regularCost = _cost;
        }
    }

    function mintForArtist() private {
        for (uint i = 0; i < 60; i ++) {
            safeMint(artist);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function isWhiteList(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function mint(uint256 _amount) external override payable {
        require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");
        
        uint256 price;
        bool _isMember = isMember(msg.sender);
        bool _isDiscount = isWhiteList(msg.sender);
        
        if (_isDiscount) {
            price = whitelistCost.mul(_amount); 
        } else if(_isMember){
            price = memberCost.mul(_amount); 
        } else {
            price = regularCost.mul(_amount); 
        }
        
        require(msg.value >= price, "not enough funds");

        uint256 amountFee = price.mulDiv(fee, SCALE); 

        for(uint256 i = 0; i < _amount; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, price - amountFee);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));

      return _tokenURI;
    }

   function safeMint(address _to) private {
        uint256 tokenId;
        
        tokenId = _tokenIdCounter.current();
        
        require(tokenId < MAX_TOKENS, "sold out!");
        _tokenIdCounter.increment();

        _safeMint(_to, order[tokenId]);
    }

    function maxSupply() external override pure returns (uint256) {
        return MAX_TOKENS;
    }

    function canMint(address) external override pure returns (uint256) {
        return MAX_MINTAMOUNT;
    }
}