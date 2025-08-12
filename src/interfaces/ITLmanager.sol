//SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

interface ITokenLaunchManager {
    event ProjectCreated(
        address indexed creator,
        address token,
        address nft,
        address fundsManager,
        uint256 icoId
    );

    function createProject(
        string memory tokenName,
        string memory tokenSymbol,
        string memory erc721Name,
        string memory erc721Symbol,
        string memory baseURI
    )
        external
        returns (
            address token,
            address erc721,
            address fundsManager,
            uint256 icoID
        );
}
