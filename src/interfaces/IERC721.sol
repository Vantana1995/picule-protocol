// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IERC721 {
    function safeMint(address to) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function balanceOf(address owner) external returns (uint256);

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setMaxSupply(uint256 amount) external;

    function maxSupply() external returns (uint256);
}
