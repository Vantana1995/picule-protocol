//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IICO {
    function createRequest(
        address token,
        address nft,
        address manager,
        address fundsManager
    ) external returns (uint256 requestId, bool icoStarted);

    function contribution(uint numOfRequest) external payable;

    function requestYourToken(uint numOfRequest) external returns (uint amount);

    function refund(uint numOfRequest) external;

    function getRequestInfo(
        uint _numOfRequest
    )
        external
        view
        returns (
            address ercToken,
            address erc721,
            address manager,
            address fundsManager,
            uint target,
            uint deadline,
            uint minimum,
            uint value,
            uint raised,
            bool completed
        );

    function getContributorValue(
        uint _numOfProject,
        address contributor
    ) external view returns (uint256 value);
}
