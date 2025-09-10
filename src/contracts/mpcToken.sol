// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import {ERC20Constructor} from "./erc20Constructor.sol";

contract MrPiculeToken is ERC20Constructor {
    uint256 public constant MAX_SUPPLY = 10000000000000 * 10 ** 18;
    uint256 public constant BURN_LIMIT = 2000000000000 * 10 ** 18;
    uint256 public constant ICO_SUPPLY = 10000000 * 10 ** 18;
    address private _owner;
    address private fundsManager;
    address private icoContract;

    bool public initialized = false;
    bool public burnLimitExceed = false;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    modifier onlyRestricted() {
        require(
            msg.sender == address(fundsManager) ||
                msg.sender == address(icoContract),
            "Caller is not swap contract"
        );
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function initialize(
        address _fundsManager,
        address _icoContract
    ) public initializer {
        super.initialize("MrPiculeToken", "MPC");
        fundsManager = _fundsManager;
        icoContract = _icoContract;
        approve(_icoContract, type(uint256).max);
        approve(_fundsManager, type(uint256).max);
        initialized = true;
        allTokenMinted = false;
    }

    function mint(
        address to,
        uint256 amount
    ) public override onlyRestricted returns (bool) {
        return super.mint(to, amount);
    }

    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }
}
