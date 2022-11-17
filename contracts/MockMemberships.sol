// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockMemberships is ERC1155 {
     constructor(uint count1, uint count2) ERC1155("https://game.example/api/item/3.json") {
        _mint(msg.sender, 1, count1, "");
        _mint(msg.sender, 2, count2, "");
    }
}