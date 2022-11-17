// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDrop {
    struct Info {
        uint256 regularCost;
        uint256 memberCost;
        uint256 whitelistCost;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 maxMintPerAddress;
        uint256 maxMintPerTx;
    }

    struct SupplyRemainingPerFaction {
        uint256 terraSupplyRemaining;
        uint256 aquaSupplyRemaining;
        uint256 ignisSupplyRemaining;
    }
    
    function mintCost(address _minter) external view returns(uint256);
    function canMint(address _minter) external view returns (uint256, uint256, uint256);
    function mint(uint256 _amount, bytes32 faction) external payable;
    function maxSupply() external view returns (uint256);
    function getInfo() external view returns (Info memory, SupplyRemainingPerFaction memory);
}