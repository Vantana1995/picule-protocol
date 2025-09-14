// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IERC20} from "../interfaces/IERC20.sol";

contract TreasuryController {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, " You are not an owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function executeCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external onlyOwner returns (bool success, bytes memory result) {
        (success, result) = target.call{value: value}(data);
    }

    function withdrawAllETH(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH");
        (bool success, ) = payable(to).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    function withdrawAllTokens(address token, address to) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens");
        IERC20(token).transfer(to, balance);
    }
}
