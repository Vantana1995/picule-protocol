//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function burn(uint value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to, uint value) external returns (bool);

    function balanceOf(address owner) external returns (uint256);
}
