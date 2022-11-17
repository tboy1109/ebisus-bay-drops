// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../interfaces/IDrop.sol";

contract Aunah is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private memberPrice = 500 ether;
    uint256 private normalPrice = 600 ether;
    uint128 constant MAX_TOKENS = 81;
    string baseURI = "ipfs://QmU7gdQnyR3HwBpyEfEjyEnru1oLP5uYz9WRDDguu6pSpY";

    modifier onlyOne(uint _count) {
        require(_count ==1 , "not mint more than one");
        _;
    }

    constructor(address _memberships, address _artist, uint16[] memory _order) ERC721("Aunah", "CWAU") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        order = _order;
        fee = 500;
    }

    function getInfo() external override view returns (Info memory) {
        Info memory allInfo;
        allInfo.regularCost = normalPrice;
        allInfo.memberCost = memberPrice;
        allInfo.maxSupply = MAX_TOKENS;
        allInfo.totalSupply = super.totalSupply();
        allInfo.maxMintPerTx = 1;

        return allInfo;
    }

    function mintCost(address _minter) external override view returns(uint256) {
        if (isMember(_minter)) {
            return memberPrice;
        } else {
            return normalPrice;
        }
    }
    
    function setCost(uint256 _cost, bool isMember) external onlyOwner {
        if (isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(uint256 _amount) external override payable onlyOne(_amount) whenNotPaused {
        uint256 price;
        bool _isMember = isMember(msg.sender);

        if(_isMember){
            price = memberPrice; 
        } else {
            price = normalPrice; 
        }
        
        require(msg.value >= price, "not enough funds");

        uint256 amountFee = price.mulDiv(fee, SCALE); 

        safeMint(msg.sender);
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
        return 1;
    }   
}