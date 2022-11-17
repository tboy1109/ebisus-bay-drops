// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";

contract Fractals  is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private memberPrice = 250 ether;
    uint256 private normalPrice = 300 ether;
    uint256 private MAX_TOKENS = 50;
    string baseURI = "ipfs://QmUfsQv8ETCLjzw5H29CqcgQ4oZucjheF5hsqkzjoWy1hk";
    
    modifier onlyOne(uint _count) {
        require(_count ==1 , "not mint more than one");
        _;
    }

    constructor(address _memberships, address _artist, uint16[] memory _order) ERC721("Fractals ", "FL") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        order = _order;
        fee  = 500;
    }
   
    function setCost(uint256 _cost, bool _isMember) external onlyOwner {
        if (_isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(uint256 _amount) public onlyOne(_amount) payable {
        bool _isMember = isMember(msg.sender);
        uint256 amountDue;    
        
        if(_isMember) {
            amountDue = memberPrice.mul(_amount); 
        } else {
            amountDue = normalPrice.mul(_amount); 
        }
        require(msg.value >= amountDue, "not enough funds");
        uint amountFee = amountDue.mulDiv(fee, SCALE); 

        safeMint(msg.sender);

        _asyncTransfer(artist, amountDue - amountFee);
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json"));

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