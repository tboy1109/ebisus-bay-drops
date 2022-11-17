// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../interfaces/IDrop.sol";

contract Skybox is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;
    
    uint256 private whitelistCost = 4000 ether;
    uint256 private memberCost = 4000 ether;
    uint256 private regularCost = 5000 ether;

    uint128 constant MAX_TOKENS = 2100;
    uint64 constant MAX_MINTAMOUNT = 3;
    uint64 private currentChunkIndex;
    mapping(address => bool) whitelist;
    string baseURI = "https://www.lazyhorseraceclub.com/skyboxmeta";
    uint256 public startedAt;
    uint256 public lockPeriod;

    constructor(address _memberships, address _artist) ERC721("Skybox", "Sky Box") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        fee = 1000;
        startedAt = block.timestamp;
        lockPeriod = 12 hours;
    }

    function setStartTime(uint _startTime) external onlyOwner {
        startedAt = _startTime;
    }

    function getLen() public view returns(uint) {
        return order.length;
    }

    function setLockPeriod(uint256 _period) external onlyOwner {
        lockPeriod = _period;
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

    function addWhiteList(address[] calldata _addresses) public onlyOwner {
        uint len = _addresses.length;
        for(uint i = 0; i < len; i ++) {
            whitelist[_addresses[i]] = true;
        }        
    }
    
    function addWhiteListAddress(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function removeWhiteList(address _address) public onlyOwner {
        if (whitelist[_address]) {
            delete whitelist[_address];
        }
    }

    function mintCost(address _minter) external override view returns(uint256) {
        if (block.timestamp < startedAt + lockPeriod && isWhiteList(_minter)) {
            return whitelistCost;
        } else if (isMember(_minter)) {
            return memberCost;
        } else {
            return regularCost;
        }
    }

    function isWhiteList(address _address) public view returns (bool) {
        return whitelist[_address];
    }
    
    function setRegularCost(uint256 _cost) external onlyOwner {
        regularCost = _cost;
    }

    function setMemberCost(uint256 _cost) external onlyOwner {
        memberCost = _cost;
    }

    function setWhitelistCost(uint256 _cost) external onlyOwner {
        whitelistCost = _cost;
    }

    function mintForArtist(uint256 num) external onlyOwner {
        for (uint i = 0; i < num; i ++) {
            safeMint(artist);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function mint(uint256 _amount) external override whenNotPaused payable {
        require(_amount > 0, "invalid amount");
        
        uint256 price;
       
        if (isClosedMint()) {
            require(_amount == 1, "only can mint one this time");

            if (isWhiteList(msg.sender)) {
                price = whitelistCost;
                whitelist[msg.sender] = false;
            } else {
                revert("whitelist only can mint this time");
            }
        } else {
            require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");

            bool _isMember = isMember(msg.sender);
            if (_isMember){
                price = memberCost.mul(_amount); 
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

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));

      return _tokenURI;
    }

   function safeMint(address _to) private {
        uint256 tokenId;
        
        tokenId = _tokenIdCounter.current();
        
        require(tokenId < MAX_TOKENS - 100, "sold out!");
        _tokenIdCounter.increment();

        _safeMint(_to, order[tokenId]);
    }

    function maxSupply() external override pure returns (uint256) {
        return MAX_TOKENS;
    }

    function canMint(address _address) external override view returns (uint256) {
        if(isClosedMint()){
            if(isWhiteList(_address)){
                return 1;
            } else {
                return 0;
            }
        }
        return MAX_MINTAMOUNT;
    }

    function isClosedMint() private view returns (bool){
        return block.timestamp < (startedAt + lockPeriod);
    }
}