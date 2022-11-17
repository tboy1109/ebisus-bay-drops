// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BarnCat is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    uint16[] order;
    uint128 constant MAX_TOKENS = 2000;
    uint8 private currentChunkIndex;
    string baseURI = "https://www.lazyhorseraceclub.com/barncatmeta";

    constructor() ERC721("Barn Cat", "BARNCAT") {
    }

    function getLen() public view returns(uint) {
        return order.length;
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


    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function airdropMint(address _sender, uint256 _amount) external onlyOwner{
        for (uint256 i = 0; i < _amount; i ++) {
            safeMint(_sender);
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
}