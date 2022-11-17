//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoLovers is ERC721, ERC721Enumerable, Ownable {
    address private constant receiver =
        0xE3393D0aa89ddCa7Afb871c921d28024df23942F;
    uint256 private constant TOTAL_SUPPLY = 50;
    string private _rootURI =
        "ipfs://QmZ6LNWNwCgzZ7JpAve3SEoJRWjDekKw7jQZG5GKbFC2WA";

    constructor() ERC721("Crypto Lovers", "CryptoLovers") Ownable() {
        for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
            safeMint(i + 1);
        }
    }

    function setRootUri(string calldata _root) public onlyOwner {
        _rootURI = _root;
    }

    function safeMint(uint256 _tokenId) private {
        _safeMint(receiver, _tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

        return
            string(
                abi.encodePacked(
                    _rootURI,
                    "/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }
}
