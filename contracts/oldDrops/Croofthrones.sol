// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../SafeMathLite.sol";
import "../SafePct.sol";
import "../NewBaseDrop.sol";
import "../interfaces/IDrop.sol";

contract Croofthrones is IDrop, BaseDrop {
    using Counters for Counters.Counter;
    using SafePct for uint256;
    using SafeMathLite for uint256;
    Counters.Counter public _tokenIdCounter;

    uint256 private whitelistCost = 160 ether;
    uint256 private memberCost = 180 ether;
    uint256 private regularCost = 220 ether;

    uint128 constant MAX_TOKENS = 2500;
    uint64 constant MAX_MINTAMOUNT = 7;
    uint64 private currentChunkIndex;
    string baseURI =
        "https://ipfs.io/ipfs/QmYMramQceiHTuNWBhDn7ipj1yzvjchJjWPmhEN7oRayK6";
    mapping(address => bool) whitelist;

    constructor(
        address _marketContract,
        address _artist,
        uint16[] memory _order
    ) ERC721("Cro of Thrones", "COT") {
        marketContract = _marketContract;
        artist = _artist;
        order = _order;
        fee = 1500;

        mintForArtist();
    }

    function getLen() public view returns (uint256) {
        return order.length;
    }

    function setSequnceChunk(uint8 _chunkIndex, uint16[] calldata _chunk)
        public
        onlyOwner
    {
        require(currentChunkIndex <= _chunkIndex, "chunkIndex exists");

        if (_chunkIndex == 0) {
            order = _chunk;
        } else {
            uint256 len = _chunk.length;
            for (uint256 i = 0; i < len; i++) {
                order.push(_chunk[i]);
            }
        }
        currentChunkIndex = _chunkIndex + 1;
    }

    function getInfo() external view override returns (Info memory) {
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
        uint256 len = _addresses.length;
        for (uint256 i = 0; i < len; i++) {
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

    function mintCost(address _minter)
        external
        view
        override
        returns (uint256)
    {
        if (isWhiteList(_minter)) {
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

    function mintForArtist() private {
        for (uint256 i = 0; i < 25; i++) {
            safeMint(artist);
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(uint256 _amount) external payable override whenNotPaused {
        require(_amount <= MAX_MINTAMOUNT, "not mint more than max amount");

        uint256 price;

        if (isWhiteList(msg.sender)) {
            price = whitelistCost.mul(_amount);
        } else {
            bool _isMember = isMember(msg.sender);
            if (_isMember) {
                price = memberCost.mul(_amount);
            } else {
                price = regularCost.mul(_amount);
            }
        }

        require(msg.value >= price, "not enough funds");

        uint256 amountFee = price.mulDiv(fee, SCALE);

        for (uint256 i = 0; i < _amount; i++) {
            safeMint(msg.sender);
        }
        _asyncTransfer(owner(), amountFee);
        _asyncTransfer(artist, price - amountFee);
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

        string memory _tokenURI = string(
            abi.encodePacked(baseURI, "/", Strings.toString(_tokenId), ".json")
        );

        return _tokenURI;
    }

    function safeMint(address _to) private {
        uint256 tokenId;

        tokenId = _tokenIdCounter.current();

        require(tokenId < MAX_TOKENS, "sold out!");
        _tokenIdCounter.increment();

        _safeMint(_to, order[tokenId]);
    }

    function maxSupply() external pure override returns (uint256) {
        return MAX_TOKENS;
    }

    function canMint(address) external pure override returns (uint256) {
        return MAX_MINTAMOUNT;
    }
}
