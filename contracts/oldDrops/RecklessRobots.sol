// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../interfaces/IDrop.sol";

contract RecklessRobots is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private whitelistCost = 200 ether;
    uint256 private memberCost = 200 ether;
    uint256 private regularCost = 300 ether;
    uint64 constant MAX_TOKENS = 2100;
    uint8 constant MAX_MINTAMOUNT = 10;
    uint8 private currentChunkIndex;
    address lootContract = 0xEd34211cDD2cf76C3cceE162761A72d7b6601E2B; // mainnet
    // address lootContract = 0x2074D6a15c5F908707196C5ce982bd0598A666f9; // testnet
    mapping(address => bool) whitelist;
    string baseURI = "ipfs://QmXULW4NEaHe3SELWLMHGBQy7MwVN14CRMXAtV2ipLmnpw";
    
    constructor(address _memberships, address _artist) ERC721("Reckless Robots", "RECK") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        fee = 1000;

        mintForArtist();
    }

    function getLen() public view returns(uint) {
        return order.length;
    }

    function setLootContractAddress(address _lootContract) external onlyOwner {
        lootContract = _lootContract;
    }

    function hasMillionsLoot(address _address) internal view returns (bool) {
        uint balance = IERC20(lootContract).balanceOf(_address);

        if (balance >= 8000000) {
            return true;
        }

        return false;
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

    function addWhitelistAddress(address _address) public onlyOwner {
        whitelist[_address] = true;
    }
    
    function addWhiteList(address[] calldata _addresses) public onlyOwner {
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
        if (isWhiteList(_minter) || hasMillionsLoot(_minter)) {
            return whitelistCost;
        } else if (isMember(_minter)) {
            return memberCost;
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

    function mintForArtist() internal {
        for (uint i = 1; i <= 35; i ++) {
            _safeMint(artist, i);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function isWhiteList(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function mint(uint256 _amount) external override whenNotPaused payable {
        require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");
        
        uint256 price;
        bool _isDiscount = isWhiteList(msg.sender);
        
        if (_isDiscount || hasMillionsLoot(msg.sender)) {
            price = whitelistCost.mul(_amount); 
        } else {
            bool _isMember = isMember(msg.sender);
            if(_isMember){
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
        
        // consider we mint 35 nfts for aritst;
        require(tokenId < MAX_TOKENS - 35, "sold out!");
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