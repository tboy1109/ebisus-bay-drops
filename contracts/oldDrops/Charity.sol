// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../BaseDrop.sol";
import "../Base64.sol";

contract Charity is BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private editionOpenPeriod = 6 days; 
    uint256 private editionCloseTime;
    uint256 internal memberPrice = 100 ether;
    uint256 public normalPrice = 100 ether;

    modifier isEditionOpened() {
        require(block.timestamp < editionCloseTime, "The edition is closed");
        _;
    }

    constructor(address _artist) ERC721("Space Crystal Unicorns", "SCU") {
        artist = _artist;

        mintForDeployer(1);
    }

    // set the edition open period days
    function setEditionOpenPeriod(uint256 _editionOpenPeriod) public onlyOwner {
        editionOpenPeriod = _editionOpenPeriod * 1 days;
    }

    function startEditionOpen() public onlyOwner {
        editionCloseTime = block.timestamp.add(editionOpenPeriod);
    }

    function setCost(uint256 _cost) public onlyOwner {
            normalPrice = _cost;
    }

    function mint(uint256 _count) public payable isEditionOpened {
        require(_count > 0, "mint at least one...");
        uint256 price;
            price = normalPrice; 

        uint256 amountDue = price * _count;
        require(msg.value >= amountDue, "not enough funds");

        for (uint256 i = 0; i < _count; i++) {
            safeMint(msg.sender);
        }
        _asyncTransfer(artist, amountDue );
    }

    function mintForDeployer(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            safeMint(msg.sender);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return buildMetadata(_tokenId);
    }

    function safeMint(address _to) internal {
        uint256 tokenId;
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(_to, tokenId);
    }

    function buildMetadata(uint256 _tokenId)
        public
        pure
        returns (string memory)
    {
        string memory tokenName = string(
            abi.encodePacked("Space Crystal Unicorns # ", Strings.toString(_tokenId))
        );

        if (_tokenId == 1) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"',
                                    tokenName,
                                    '",'
                                    '"image":"ipfs://Qmbdqj2DB3N9bYfoXu1y7e4P5a8xHctm3N3bTTMSP2o99V",',
                                    '"description": "They are magical! Their strength lies in feeling and finding those in need."',
                                    "}"
                                )
                            )
                        )
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"',
                                    tokenName,
                                    '",'
                                    '"image":"ipfs://QmcATmajATFiAidiDTuq7uoJPFBugLpDoVjFPR2wRTMMda",',
                                    '"description": "They are magical! Their strength lies in feeling and finding those in need."',
                                    "}"
                                )
                            )
                        )
                    )
                );
        }
    }
}
