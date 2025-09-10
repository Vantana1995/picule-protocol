//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Library} from "../libraries/Library.sol";
import {IPair} from "../interfaces/IPair.sol";
import {IWMON} from "../interfaces/IWMON.sol";
import {Transfer} from "../libraries/TransferLib.sol";
import {IRouter} from "../interfaces/IRouter.sol";

contract Router is IRouter {
    address public immutable factory;
    address public immutable WMON;
    address public pairImplementation;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "ROUTER: EXPIRED");
        _;
    }

    constructor(address _factory, address _wmon, address _pair) {
        factory = _factory;
        WMON = _wmon;
        pairImplementation = _pair;
    }

    receive() external payable {
        require(msg.sender == WMON);
    }

    fallback() external payable {
        revert("Use WMON directly");
    }

    //FUNCTION FOR ADD LIQUIDITY

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        override
        ensure(deadline)
        returns (uint amountA, uint amountB, uint liquidity)
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = Library.pairFor(
            factory,
            tokenA,
            tokenB,
            pairImplementation
        );
        Transfer.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        Transfer.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountEthMin,
        address to,
        uint deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint amountToken, uint amountEth, uint liquidity)
    {
        (amountToken, amountEth) = _addLiquidity(
            token,
            WMON,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountEthMin
        );
        address pair = Library.pairFor(
            factory,
            token,
            WMON,
            pairImplementation
        );
        Transfer.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWMON(WMON).deposit{value: amountEth}();
        assert(IWMON(WMON).transfer(pair, amountEth));
        liquidity = IPair(pair).mint(to);

        if (msg.value > amountEth)
            Transfer.safeTransferETH(msg.sender, msg.value - amountEth);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = Library.pairFor(
            factory,
            tokenA,
            tokenB,
            pairImplementation
        );
        IPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = IPair(pair).burn(to);
        (address token0, ) = Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "ROUTER: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "ROUTER: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        public
        override
        ensure(deadline)
        returns (uint amountToken, uint amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WMON,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        Transfer.safeTransfer(token, to, amountToken);
        IWMON(WMON).withdraw(amountETH);
        Transfer.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address pair = Library.pairFor(
            factory,
            tokenA,
            tokenB,
            pairImplementation
        );
        uint value = approveMax ? type(uint256).max : liquidity;
        IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address pair = Library.pairFor(
            factory,
            token,
            WMON,
            pairImplementation
        );
        uint value = approveMax ? type(uint256).max : liquidity;
        IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = Library.getAmountsOut(
            factory,
            amountIn,
            pairImplementation,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "ROUTER: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        Transfer.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = Library.getAmountsIn(
            factory,
            amountOut,
            pairImplementation,
            path
        );
        require(amounts[0] <= amountInMax, "ROUTER: EXCESSIVE_INPUT_AMOUNT");
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        Transfer.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WMON, "ROUTER: INVALID_PATH");
        amounts = Library.getAmountsOut(
            factory,
            msg.value,
            pairImplementation,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "ROUTER: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWMON(WMON).deposit{value: amounts[0]}();
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        assert(IWMON(WMON).transfer(pair, amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WMON, "ROUTER: INVALID_PATH");
        amounts = Library.getAmountsIn(
            factory,
            amountOut,
            pairImplementation,
            path
        );
        require(amounts[0] <= amountInMax, "ROUTER: EXCESSIVE_INPUT_AMOUNT");
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        Transfer.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, address(this));
        IWMON(WMON).withdraw(amounts[amounts.length - 1]);
        Transfer.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        require(path[path.length - 1] == WMON, "ROUTER: INVALID_PATH");
        amounts = Library.getAmountsOut(
            factory,
            amountIn,
            pairImplementation,
            path
        );
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "ROUTER: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        Transfer.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, address(this));
        IWMON(WMON).withdraw(amounts[amounts.length - 1]);
        Transfer.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WMON, "ROUTER: INVALID_PATH");
        amounts = Library.getAmountsIn(
            factory,
            amountOut,
            pairImplementation,
            path
        );
        require(amounts[0] <= msg.value, "ROUTER: EXCESSIVE_INPUT_AMOUNT");
        IWMON(WMON).deposit{value: amounts[0]}();
        address pair = Library.pairFor(
            factory,
            path[0],
            path[1],
            pairImplementation
        );
        assert(IWMON(WMON).transfer(pair, amounts[0]));
        _swap(amounts, path, to);
        if (msg.value > amounts[0])
            Transfer.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // LIBRARY FUNCTIONS

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure override returns (uint amountB) {
        return Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure override returns (uint amountOut) {
        return Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure override returns (uint amountIn) {
        return Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view override returns (uint[] memory amounts) {
        return
            Library.getAmountsOut(factory, amountIn, pairImplementation, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view override returns (uint[] memory amounts) {
        return
            Library.getAmountsIn(factory, amountOut, pairImplementation, path);
    }

    // INTERNAL FUNCTION SECTION

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal view returns (uint amountA, uint amountB) {
        address pair = Library.pairFor(
            factory,
            tokenA,
            tokenB,
            pairImplementation
        );
        require(pair != address(0), "ROUTER: PAIR_NOT_EXIST");
        (uint reserveA, uint reserveB, ) = IPair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "ROUTER: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "ROUTER: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // INTERNAL FUNCTIONS FOR PROVIDING SWAPS

    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairImplementation
                )
                : _to;
            address pair = Library.pairFor(
                factory,
                input,
                output,
                pairImplementation
            );
            require(pair != address(0), "ROUTER: PAIR_NOT_FOUND");
            IPair(pair).swap(amount0Out, amount1Out, to);
        }
    }
}
