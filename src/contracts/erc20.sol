// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20Constructor} from "./erc20Constructor.sol";

contract ERC20 is ERC20Constructor {
    address private icoContract;
    address private fundsManager;
    address private router;
    uint256 public constant MAX_SUPPLY = 100000000000 * 10 ** 18;
    uint256 public constant BURN_LIMIT = 20000000000 * 10 ** 18;
    uint256 public constant ICO_SUPPLY = 10000000 * 10 ** 18;

    bool private initialized = false;
    bool public burnLimit = false;

    modifier onlyRestricted() {
        require(
            msg.sender == icoContract || msg.sender == fundsManager,
            "ERC20: YOU_CANT_CALL_THIS_FUNCTION"
        );
        _;
    }

    modifier onlyOnce() {
        require(!initialized, "ERC20: already initialized");
        _;
        initialized = true;
    }

    constructor() {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _icoContract,
        address _router,
        address _fundsManager
    ) external onlyOnce {
        super.initialize(_name, _symbol);
        icoContract = _icoContract;
        router = _router;
        super.approve(_fundsManager, type(uint256).max);
        super.approve(router, type(uint256).max);
        super.approve(icoContract, type(uint256).max);
        fundsManager = _fundsManager;
        allTokenMinted = false;
    }

    function mint(
        address to,
        uint256 amount
    ) public override onlyRestricted returns (bool) {
        return super.mint(to, amount);
    }
}
