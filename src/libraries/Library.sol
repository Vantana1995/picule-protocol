//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {IPair} from "../interfaces/IPair.sol";

library Library {
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Library: ZERO_ADDRESS");
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        address erc20
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        assembly ("memory-safe") {
            mstore(0x00, token0)
            mstore(0x20, token1)
            let salt := keccak256(0x00, 0x40)
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), factory)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), erc20)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            pair := and(
                keccak256(add(ptr, 0x43), 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        address erc20
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IPair(
            pairFor(factory, tokenA, tokenB, erc20)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function quote(
        uint amountA,
        uint reserve0,
        uint reserve1
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "Library: INSUFFICIENT_AMOUNT");
        require(
            reserve0 > 0 && reserve1 > 0,
            "Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * reserve1) / reserve0;
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "Library:INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Library: INSUFFICIENT_LIQUIDITY"
        );
        uint amountWithFee = amountIn * 997;
        uint numerator = amountWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "Library:INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "Lbrary: INSUFFICIENT_LIQUIDITY"
        );
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsOut(
        address factory,
        uint amountIn,
        address erc20,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1],
                erc20
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    function getAmountsIn(
        address factory,
        uint amountOut,
        address erc20,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length == 2, "Library:INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i],
                erc20
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
