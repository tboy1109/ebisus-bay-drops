// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../interfaces/IDrop.sol";

contract Slothty is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;
    Counters.Counter public _artistCounter;

    uint256 private memberCost = 249 ether;
    uint256 private whitelistCost = 249 ether;
    uint256 private regularCost = 299 ether;
    uint64 constant MAX_TOKENS = 8888;
    uint8 constant MAX_MINTAMOUNT = 10;
    uint8 private currentChunkIndex;
    mapping(address => bool) whitelist;
    string baseURI = "ipfs://QmNWJw5VZKkbiGKEaUEViniYQHDV3rc15R4EHBj1xPoCw3";
    bool public revealed = false;
    string public notRevealedUri = "ipfs://Qmc4bJhZqbuSi7N15AtStyBV4BvxEvqP1X1RJpfNUuYLHF/Hidden.json";
    constructor(address _memberships, address _artist) ERC721("3DSLOTHTY", "3DSLOTHTY") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        fee = 1000;

        _artistCounter.increment();
    }

    function getLen() public view returns(uint) {
        return order.length;
    }

    function addWhitelistAddress(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function addWhiteList(address[] calldata _addresses) public onlyOwner {
        uint len = _addresses.length;
        for(uint i = 0; i < len; i ++) {
            whitelist[_addresses[i]] = true;
        }        
    }

    function removeWhiteList(address _address) public onlyOwner {
        if (whitelist[_address]) {
            delete whitelist[_address];
        }
    }
    
    function isWhiteList(address _address) public view returns (bool) {
        return whitelist[_address];
    }
    
    function setSequnceChunk(uint8 _chunkIndex, uint16[] calldata _chunk) public onlyOwner {
        require(currentChunkIndex <= _chunkIndex, "chunkIndex exists");
        if (_chunkIndex == 0) {
            order = _chunk;
        } else {
            uint len = _chunk.length;
            for(uint i = 0; i < len; i ++) {
                order.push(_chunk[i]);
            }
        }
        currentChunkIndex = _chunkIndex + 1;
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

    function mintCost(address _minter) external override view returns(uint256) {
        if (isMember(_minter)) {
            return memberCost;
        } else if (isWhiteList(_minter)) {
            return whitelistCost;
        } else {
            return regularCost;
        }
    }
    
    function setMemberCost(uint256 _cost) external onlyOwner {
        memberCost = _cost;
    }

    function setWhitelistCost(uint256 _cost) external onlyOwner {
        whitelistCost = _cost;
    }

    function setRegularCost(uint256 _cost) external onlyOwner {
        regularCost = _cost;
    }

    function mintForArtist(uint256 num) external onlyOwner {
        uint256 current = _artistCounter.current();
        for (uint i = current; i < current + num; i ++) {
            _safeMint(artist, i);
            _artistCounter.increment();
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function airdropMint(address _sender, uint256 _amount) external onlyOwner{
        for (uint256 i = 0; i < _amount; i ++) {
            safeMint(_sender);
        }
    }

    function mint(uint256 _amount) external override payable whenNotPaused {
        require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");

        uint256 price;
        bool _isMember = isMember(msg.sender);
        
        if (_isMember) {
           price = memberCost.mul(_amount);  
        } else {
            bool _isDiscount = isWhiteList(msg.sender);
            if (_isDiscount) {
                price = whitelistCost.mul(_amount); 
            } else {
                price = regularCost.mul(_amount); 
            }
        }

        require(msg.value >= price, "not enough funds");
       
        uint256 amountFee = price.mulDiv(fee, SCALE); 
        for(uint256 i = 0; i < _amount; i++){
            safeMint(msg.sender);
        }

        _asyncTransfer(artist, price - amountFee);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      if(revealed == false) {
            return notRevealedUri;
        }
      string memory _tokenURI = string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));

      return _tokenURI;
    }

   function safeMint(address _to) private {
        uint256 tokenId;
        
        tokenId = _tokenIdCounter.current();
        
        // consider we mint 35 nfts for aritst;
        require(tokenId < MAX_TOKENS - 100, "sold out!");
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