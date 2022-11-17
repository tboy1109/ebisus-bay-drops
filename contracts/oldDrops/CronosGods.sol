// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "hardhat/console.sol";

contract CronosGods is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private memberPrice = 295 ether;
    uint256 private normalPrice = 350 ether;
    uint256 private memberLootPrice = 37000000 ether;
    uint256 private normalLootPrice = 43800000 ether;
    uint64 constant MAX_TOKENS = 1520;
    uint32 constant MAX_MINTAMOUNT = 5;
    address lootAddress = 0xEd34211cDD2cf76C3cceE162761A72d7b6601E2B; // mainnet
    // address lootAddress = 0x2074D6a15c5F908707196C5ce982bd0598A666f9; // testnet
    string baseURI = "ipfs://Qmc8Z622wy9zCeFnFgwyAsh7vNdYt8idYcmmsRkCXtXMAx";
    uint immutable reducedTime;
    mapping(address => uint) balances;

    constructor(address _memberships, address _artist, uint16[] memory _order) ERC721("CronoGods", "GODS") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        order = _order;
        fee = 1000;
        reducedTime = block.timestamp + 2 hours;

        mintForArtist();
    }

    function setLootAddress(address _lootAddress) external onlyOwner {
        lootAddress = _lootAddress;
    }

    function isReducedTime() public view returns (bool) {
        return block.timestamp <= reducedTime;
    }

    function setLootCost(uint256 _cost, bool _isMember) external onlyOwner {
        if (_isMember) {
            memberLootPrice = _cost;
        } else {
            normalLootPrice = _cost;
        }
    }

    function setCost(uint256 _cost, bool _isMember) external onlyOwner {
        if (_isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }
    
    function mintCost(address _minter) external view returns(uint256) {
        if (isMember(_minter)) {
            return memberPrice;
        } else {
            return normalPrice;
        }
    }

    function mintLootCost(address _minter) external view returns(uint256) {
        if (isMember(_minter)) {
            return memberLootPrice;
        } else {
            return normalLootPrice;
        }
    }   

    function mintForArtist() private {
        for (uint i = 0; i < 20; i ++) {
            safeMint(artist);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(uint256 _amount) external whenNotPaused payable {
        require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");
        
        uint256 amountDue;
        bool _isMember = isMember(msg.sender);

        if(isReducedTime() || _isMember){
            amountDue = memberPrice.mul(_amount); 
        } else {
            amountDue = normalPrice.mul(_amount); 
        }
        
        require(msg.value >= amountDue, "not enough funds");

        uint256 amountFee = amountDue.mulDiv(fee, SCALE); 

        for(uint256 i = 0; i < _amount; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, amountDue - amountFee);
    }
    
    function mintWithLoot(uint256 _amount) external whenNotPaused {
        uint256 amountDue;
        bool _isMember = isMember(msg.sender);

        if(isReducedTime() || _isMember){
            amountDue = memberLootPrice.mul(_amount); 
        } else {
            amountDue = normalLootPrice.mul(_amount); 
        }
        require(IERC20(lootAddress).balanceOf(msg.sender) >= amountDue, "not enough funds");

        (bool success) = IERC20(lootAddress).transferFrom(msg.sender, address(this), amountDue);

        require(success == true, "transfer token failed");
        
        uint amountFee = amountDue.mulDiv(fee, SCALE); 
        balances[address(this)] += amountFee;
        balances[artist] += amountDue - amountFee;

        for(uint i = 0; i < _amount; i++){
            safeMint(msg.sender);
        }
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

    function maxSupply() external pure returns (uint256) {
        return MAX_TOKENS;
    }

    function canMint(address) external pure returns (uint256) {
        return MAX_MINTAMOUNT;
    }   

    function withdraw() public override virtual onlyOwner{
        super.withdraw();
        // withdraw loot
        if (balances[address(this)] > 0 ) {
            uint balance = balances[address(this)];
            balances[address(this)] = 0;
            IERC20(lootAddress).transfer(msg.sender, balance);
        }
    }

    function withdrawPayments(address payable payee) public virtual override{
         // withdraw loot
        if (balances[payee] > 0) {
            uint balance = balances[payee];
            balances[payee] = 0;
            IERC20(lootAddress).transfer(payee, balance);
            
        }
        super.withdrawPayments(payee);       
    }
}