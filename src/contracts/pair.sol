//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {LPToken} from "./lpToken.sol";
import {UQ112x112} from "../libraries/UQ112x112.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Math} from "../libraries/Math.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IPair} from "../interfaces/IPair.sol";

contract Pair is LPToken, IPair {
    using UQ112x112 for uint224;

    uint256 public MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public token0;
    address public token1;
    address public factory;
    address public autoFundsManager;

    uint256 public binaryCommission;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;

    uint private unlocked = 1;

    modifier _lock() {
        require(unlocked == 1, "Pair : LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {}

    function initialize(
        address _token0,
        address _token1,
        address initializer,
        address _factory
    ) external {
        assembly {
            // if iszero(eq(caller(),sload(factory.slot))) {
            //     mstore(0x00, 0x330c6a16)
            //     revert(0x00, 0x04)
            // }
            sstore(token0.slot, _token0)
            sstore(token1.slot, _token1)
            sstore(autoFundsManager.slot, initializer)
            sstore(factory.slot, _factory)
            sstore(unlocked.slot, 1)
            // call approve max for initializer
            mstore(0x00, shl(224, 0x095ea7b3))
            mstore(0x04, initializer)
            mstore(0x24, not(0))
            if iszero(call(gas(), _token0, 0, 0x00, 0x44, 0x00, 0x00)) {
                revert(0, 0)
            }
            if iszero(call(gas(), _token1, 0, 0x00, 0x44, 0x00, 0x00)) {
                revert(0, 0)
            }
        }
    }

    function mint(address to) external _lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint totalSupply = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / uint(_reserve0),
                (amount1 * totalSupply) / uint(_reserve1)
            );
        }
        require(liquidity > 0, "Pair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * uint(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(
        address to
    ) external _lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = _balanceOf[address(this)];
        _mintFee(_reserve0, _reserve1);

        uint256 totalSupply = _totalSupply;
        amount0 = (liquidity * _reserve0) / totalSupply;
        amount1 = (liquidity * _reserve1) / totalSupply;
        require(
            amount0 > 0 && amount1 > 0,
            "Pair: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _update(balance0, balance1, _reserve0, _reserve1);
        kLast = uint(reserve0) * uint(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to
    )
        external
        // bytes calldata data
        _lock
    {
        assembly {
            // require(amount0Out > 0 || amount1Out > 0,"Pair: INSUFFICIENT_OUTPUT_AMOUNT");
            if iszero(add(gt(amount0Out, 0), gt(amount1Out, 0))) {
                mstore(0x00, 0x4b2c5027)
                revert(0x00, 0x04)
            }

            mstore(0x40, shl(224, 0x0902f1ac))
            if iszero(call(gas(), address(), 0, 0x40, 0x04, 0x40, 0x60)) {
                mstore(0x00, 0x97dc74af)
                revert(0x00, 0x04)
            }
            mstore(0x100, mload(0x40)) // reserve0
            mstore(0x120, mload(0x60)) // reserve1
            mstore(0x140, mload(0x80)) // blockTimestampLast

            //require(amount0Out < _reserve0 && amount1Out < _reserve1,"Pair: INSUFFICIENT_LIQUIDITY");
            if iszero(
                and(gt(mload(0x100), amount0Out), gt(mload(0x120), amount1Out))
            ) {
                mstore(0x00, 0x8e60ee84)
                revert(0x00, 0x04)
            }

            let ptr := mload(0x40)
            // transfer tokens
            {
                //  address _token0
                mstore(0x1A0, sload(token0.slot))
                //  address _token1 = token1;
                mstore(0x1C0, sload(token1.slot))
                //  require(to != _token0 && to != _token1, "Pair: INVALID_TO");
                if or(eq(mload(0x1A0), to), eq(mload(0x1C0), to)) {
                    mstore(0x00, 0x065028fc)
                    revert(0x00, 0x04)
                }
                // transfer tokens
                mstore(0x40, shl(224, 0xa9059cbb))
                mstore(0x44, to)
                if gt(amount0Out, 0) {
                    mstore(0x64, amount0Out)
                    if iszero(
                        call(gas(), mload(0x1A0), 0, 0x40, 0x44, 0x00, 0x00)
                    ) {
                        mstore(0x00, 0x89b41f78)
                        revert(0x00, 0x04)
                    }
                }
                if gt(amount1Out, 0) {
                    mstore(0x64, amount1Out)
                    if iszero(
                        call(gas(), mload(0x1C0), 0, 0x40, 0x44, 0x00, 0x00)
                    ) {
                        mstore(0x00, 0xfad0e10c)
                        revert(0x00, 0x04)
                    }
                }
                // balance0 = IERC20(_token0).balanceOf(address(this));
                // balance1 = IERC20(_token1).balanceOf(address(this));
                mstore(0x40, shl(224, 0x70a08231))
                mstore(0x44, address())
                if iszero(
                    staticcall(gas(), mload(0x1A0), 0x40, 0x24, 0x160, 0x20)
                ) {
                    // balance0
                    mstore(0x00, 0xf42986c2)
                    revert(0x00, 0x04)
                }
                if iszero(
                    staticcall(gas(), mload(0x1C0), 0x40, 0x24, 0x180, 0x20)
                ) {
                    // balance1
                    mstore(0x00, 0x620a9b8e)
                    revert(0x00, 0x04)
                }
            }
            // uint amount0In = balance0 > _reserve0 - amount0Out
            switch gt(mload(0x160), sub(mload(0x100), amount0Out))
            case 1 {
                mstore(0x1E0, sub(mload(0x160), sub(mload(0x100), amount0Out)))
            }
            default {
                mstore(0x1E0, 0)
            }
            // uint amount1In = balance1 > _reserve1 - amount1Out
            switch gt(mload(0x180), sub(mload(0x120), amount1Out))
            case 1 {
                mstore(0x200, sub(mload(0x180), sub(mload(0x120), amount1Out)))
            }
            default {
                mstore(0x200, 0)
            }
            // require(amount0In > 0 || amount1In > 0,"Pair: INSUFFICIENT_INPUT_AMOUNT");
            if iszero(add(gt(mload(0x1E0), 0), gt(mload(0x200), 0))) {
                mstore(0x00, 0xff6d1c98)
                revert(0x00, 0x04)
            }

            //  require(balance0Adjusted * balance1Adjusted >= uint(_reserve0 * _reserve1) * 1000 ** 2, "Pair: K");
            {
                //  uint balance0Adjusted = balance0 * 1000 - (amount0In * 3);
                mstore(0x40, sub(mul(mload(0x160), 1000), mul(mload(0x1E0), 3)))
                //  uint balance1Adjusted = balance1 * 1000 - (amount1In * 3);
                mstore(0x60, sub(mul(mload(0x180), 1000), mul(mload(0x200), 3)))
                // balance0Adjusted * balance1Adjusted
                mstore(0x80, mul(mload(0x40), mload(0x60)))
                if lt(
                    mload(0x80),
                    mul(mul(mload(0x100), mload(0x120)), 1000000)
                ) {
                    mstore(0x00, 0x0a1d3df0)
                    revert(0x00, 0x04)
                }
            }
            // calculate binary comission
            {
                mstore(0x220, sload(binaryCommission.slot))
                // fee0
                mstore(0x240, div(mul(mload(0x1E0), 3), 1000))
                // fee1
                mstore(0x260, div(mul(mload(0x200), 3), 1000))
                // supply
                mstore(0x280, sload(_totalSupply.slot))
                // locked
                mstore(0x2A0, sload(totalLockedLp.slot))
                // newCommission
                mstore(0x2C0, mload(0x220))

                if and(gt(mload(0x280), 0), gt(mload(0x2A0), 0)) {
                    // lockedShare
                    mstore(
                        0x2E0,
                        div(
                            mul(mload(0x2A0), 1000000000000000000),
                            mload(0x280)
                        )
                    )
                    // share0
                    mstore(
                        0x300,
                        div(
                            mul(mload(0x240), mload(0x2E0)),
                            1000000000000000000
                        )
                    )
                    // share1
                    mstore(
                        0x320,
                        div(
                            mul(mload(0x260), mload(0x2E0)),
                            1000000000000000000
                        )
                    )

                    // unwrap old comission

                    //  oldShare0
                    mstore(0x00, shr(128, mload(0x220)))
                    //  oldShare1
                    mstore(
                        0x20,
                        and(mload(0x220), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    )

                    // sum and wrap new comission
                    mstore(
                        0x2C0,
                        or(
                            shl(128, add(mload(0x00), mload(0x300))),
                            add(mload(0x20), mload(0x320))
                        )
                    )
                }
                // save result
                sstore(binaryCommission.slot, mload(0x2C0))
            }

            // _update(balance0, balance1, _reserve0, _reserve1) internal function
            {
                // uint112 max - 1
                mstore(0x20, sub(shl(112, 1), 2)) // 2^112 - 2

                if iszero(
                    and(
                        iszero(gt(mload(0x160), mload(0x20))),
                        iszero(gt(mload(0x180), mload(0x20)))
                    )
                ) {
                    mstore(0x00, 0x2d18d0df) // "Pair:OVERFLOW"
                    revert(0x00, 0x04)
                }

                // uint32 blockTimestamp = uint32(block.timestamp % 2^32)
                mstore(0x220, mod(timestamp(), 0x100000000))

                // uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                mstore(0x240, sub(mload(0x220), sload(blockTimestampLast.slot)))

                // if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0)
                mstore(
                    0x260,
                    and(
                        gt(mload(0x240), 0),
                        and(gt(mload(0x100), 0), gt(mload(0x120), 0))
                    )
                )

                if mload(0x260) {
                    // Q112
                    mstore(0x280, exp(2, 112))

                    // price0CumulativeLast += (reserve1 * Q112 / reserve0) * timeElapsed
                    mstore(
                        0x2A0,
                        div(mul(mload(0x120), mload(0x280)), mload(0x100))
                    )
                    sstore(
                        price0CumulativeLast.slot,
                        add(
                            sload(price0CumulativeLast.slot),
                            mul(mload(0x2A0), mload(0x240))
                        )
                    )

                    // price1CumulativeLast += (reserve0 * Q112 / reserve1) * timeElapsed
                    mstore(
                        0x2C0,
                        div(mul(mload(0x100), mload(0x280)), mload(0x120))
                    )
                    sstore(
                        price1CumulativeLast.slot,
                        add(
                            sload(price1CumulativeLast.slot),
                            mul(mload(0x2C0), mload(0x240))
                        )
                    )
                }

                // // reserve0 = uint112(balance0)
                // sstore(reserve0.slot, mload(0x160))
                // // reserve1 = uint112(balance1)
                // sstore(reserve1.slot, mload(0x180))
                // // blockTimestampLast = blockTimestamp
                // sstore(blockTimestampLast.slot, mload(0x220))

                mstore(
                    0x00,
                    or(
                        or(shl(224, mload(0x220)), shl(112, mload(0x180))),
                        mload(0x160)
                    )
                )
                sstore(reserve0.slot, mload(0x00))

                // emit Sync(reserve0, reserve1)
                mstore(0x00, mload(0x160))
                mstore(0x20, mload(0x180))
                log1(
                    0x00,
                    0x40,
                    0x1c411e9a96e4d4b48e8453e0c7c1b6fa46387d2ad3c6c831a0052c364a7e165f
                )
            }

            mstore(0x00, mload(0x1E0))
            mstore(0x20, mload(0x200))
            mstore(0x40, amount0Out)
            mstore(0x60, amount1Out)
            log3(
                0x00,
                0x80,
                0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822,
                caller(),
                to
            )
        }
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function skim(address to) external _lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) - reserve0
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    function sync() external _lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function lock(address from, uint256 value) external {
        require(
            msg.sender == autoFundsManager,
            " You can not call this function"
        );
        require(_balanceOf[from] >= value, "Insufficient balance to lock");
        _balanceOf[from] -= value;
        _balanceOf[address(0)] += value;
        totalLockedLp += value;
        emit Transfer(from, address(0), value);
    }

    function _binaryCommission() external view returns (uint128, uint128) {
        uint256 packed = binaryCommission;
        uint128 commission0 = uint128(packed >> 128);
        uint128 commission1 = uint128(packed);
        return (commission0, commission1);
    }

    function _update(
        uint balance0,
        uint balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= type(uint112).max - 1 &&
                balance1 <= type(uint112).max - 1,
            "Pair:OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 3 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            price0CumulativeLast +=
                uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        address feeTo = IFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * uint(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = _totalSupply * (rootK - rootKLast);
                    uint denominator = rootK * 5 + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Pair: TRANSFER_FAILED"
        );
    }

    function lock() external {
        require(
            msg.sender == autoFundsManager,
            "You can not call this function"
        );
        unlocked = 0;
    }

    function unlock(address to) external returns (uint256 liquidity) {
        require(
            msg.sender == autoFundsManager,
            "You can not call this function"
        );
        unlocked = 1;
        liquidity = this.mint(to);
    }
}
