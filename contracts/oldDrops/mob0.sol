// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../Base64.sol";

contract Mob0 is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint private editionOpenPeriod = 7 days; // 7 days
    uint private editionCloseTime;
    uint256 internal memberPrice = 100 ether;
    uint256 internal normalPrice = 150 ether;
    uint256 private MAX_TOKENS = 1111;
    bool revealed = false;
    
    modifier isEditionOpened() {
        require(block.timestamp < editionCloseTime, "The edition is closed");
        _;
    }

    constructor(address _memberships, address _artist, uint16[] memory _order) ERC721("Elon's Adventure", "EAV") {
        memberships = ERC1155(_memberships);
        artist = _artist;
        order = _order;
        fee = 500;
        mintForDeployer(20);
    }
    
    // set the edition open period days
    function setEditionOpenPeriod(uint _editionOpenPeriod) public onlyOwner {
        editionOpenPeriod = _editionOpenPeriod * 1 days;
    }
    
    function startEditionOpen() public onlyOwner {
        editionCloseTime = block.timestamp.add(editionOpenPeriod);
    }
   
    function setCost(uint _cost, bool isMember) public onlyOwner {
        if (isMember) {
            memberPrice = _cost;
        } else {
            normalPrice = _cost;
        }
    }

    function setMaxToken(uint256 _maxTokens) public onlyOwner {
        MAX_TOKENS = _maxTokens;
    }

    function mint(uint256 _count) public payable isEditionOpened {
        uint price;
        bool _isMember = isMember(msg.sender);

        if(_isMember){
            price = memberPrice; // 100 ether
        } else {
            price = normalPrice; // 150 ether
        }
        
        uint amountDue = price * _count;
        require(msg.value >= amountDue, "not enough funds");

        uint amountFee = amountDue.mulDiv(fee, SCALE); 

        for(uint i = 0; i < _count; i++){
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, amountDue - amountFee);
    }

    function mintForDeployer(uint256 count) internal {
        for (uint i = 0; i < count; i ++) {
            safeMint(msg.sender);
        }
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

      if(revealed == false) {
        return "no revealed";
      }
      
      return buildMetadata(_tokenId);
    }

    function buildMetadata(uint256 _tokenId) public pure returns(string memory) {
      string memory tokenName = string(abi.encodePacked("Barbara's Bay #", Strings.toString(_tokenId)));

      return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          tokenName,'",' 
                          '"image":"ipfs://QmV5wqtX54Hybh6ZQ61dE3wFBypGj8ck3f9tJo2B8Ss5Qr",', 
                          '"description": "Ebisu has many origins, all of which have lead to his current status as one of the Seven Lucky Gods. May his blessing be upon you as a guiding light in your journeys on the Cronos Chain.",',
                          '"attributes":[{"trait_type": "Background","value": "Sea"},{"trait_type": "Character","value": "Ebisu"}]',
                          '}'
                        )
                    )
                )
            )
        );
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

   function safeMint(address _to) internal {
        uint256 tokenId;
        
        tokenId = _tokenIdCounter.current();
        require(tokenId < MAX_TOKENS, "sold out!");
        _tokenIdCounter.increment();
         
        _safeMint(_to, order[tokenId]);
    }
}