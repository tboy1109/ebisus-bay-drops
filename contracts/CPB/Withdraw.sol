// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Withdraw is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
    }

    Part[] public parts;

    constructor(){
        parts.push(Part(0xd2ace13fD5AdA4351a31Cd8a1206C2da3377634D, 400));
        parts.push(Part(0x9822e949A4193EA5442F640A2e3c92C31569ACec, 200));
        parts.push(Part(0x53B4bA1a81744A1C9920b341d6EFe6F7d366B583, 200));
        parts.push(Part(0x40ce05B67D50E114cfeE3F51c8250483b4A85fF9, 200));
    }

    function shareSalesPart() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(1000));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

}