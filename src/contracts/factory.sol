//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {IFactory} from "../interfaces/IFactory.sol";
import {Pair} from "./pair.sol";
import {FundsManager} from "./fundsManager.sol";
import {IPair} from "../interfaces/IPair.sol";

contract Factory is IFactory {
    address public feeTo;
    address public feeToSetter;
    address public tlm;
    address public owner;
    address public pairImplementation;

    bool initialized = false;

    mapping(address => bool) public isAllowedCreator;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256 allPairsLength
    );

    constructor(address _feeToSetter, address _pairImplementation) {
        owner = msg.sender;
        feeToSetter = _feeToSetter;
        pairImplementation = _pairImplementation;
    }

    modifier initializer() {
        require(initialized == false, "Factory: Contract already initialized");
        _;
    }

    modifier onlyAllowed() {
        require(isAllowedCreator[msg.sender], "Not allowed");
        _;
    }

    modifier onlyRestricted() {
        require(
            msg.sender == tlm || msg.sender == owner,
            "This function can be called only from TLM contract"
        );
        _;
    }

    function initialize(address _tlm) public initializer {
        tlm = _tlm;
        initialized = true;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external onlyAllowed returns (address pair) {
        assembly {
            let implementation := sload(pairImplementation.slot)
            let ptr := mload(0x40)

            // Sort token manually (Uniswap V2 formula) and store it to safe memory slot
            switch gt(tokenA, tokenB)
            case 1 {
                mstore(0x100, tokenB)
                mstore(0x120, tokenA)
            }
            default {
                mstore(0x100, tokenA)
                mstore(0x120, tokenB)
            }

            // require(getPair[token0][token1] == address(0), "FACTORY:PAIR_EXISTS");
            mstore(ptr, mload(0x100))
            mstore(add(ptr, 0x20), getPair.slot)
            mstore(0x140, keccak256(ptr, 0x40)) // Outer slot of   getPair mapping
            mstore(ptr, mload(0x120))
            mstore(add(ptr, 0x20), mload(0x140))
            mstore(0x160, keccak256(ptr, 0x40)) // Inner slot of getPair mapping
            mstore(ptr, mload(0x120))
            mstore(add(ptr, 0x20), getPair.slot)
            mstore(0x220, keccak256(ptr, 0x40))
            mstore(ptr, mload(0x100))
            mstore(add(ptr, 0x20), mload(0x220))
            mstore(0x240, keccak256(ptr, 0x40))
            if iszero(iszero(sload(0x160))) {
                revert(0, 0)
            }

            // Salt
            mstore(0x180, mload(0x100))
            mstore(0x1A0, mload(0x120))
            mstore(0x1C0, keccak256(0x180, 0x40))

            mstore(
                0x00,
                or(
                    shr(0xe8, shl(0x60, implementation)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            mstore(
                0x20,
                or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
            )
            pair := create2(0, 0x09, 0x37, mload(0x1C0))
            // selector := 0xf8c8765e for (initialize(address, address, address, address))
            mstore(ptr, shl(224, 0xf8c8765e))
            mstore(add(ptr, 0x04), mload(0x100))
            mstore(add(ptr, 0x24), mload(0x120))
            mstore(add(ptr, 0x44), caller())
            mstore(add(ptr, 0x64), address())
            if iszero(call(gas(), pair, 0, ptr, 0x84, 0x00, 0x00)) {
                revert(0, 0)
            }

            {
                //getPair[token0][token1] = pair;
                sstore(mload(0x160), pair)
                //getPair[token1][token0] = pair;
                sstore(mload(0x240), pair)
            }

            //allPairs.push(pair);
            mstore(0x260, sload(allPairs.slot))
            mstore(0x2C0, allPairs.slot)
            mstore(0x280, keccak256(0x2C0, 0x20))
            mstore(0x2A0, add(mload(0x280), mload(0x260)))
            sstore(mload(0x2A0), pair)
            sstore(allPairs.slot, add(mload(0x260), 1))
            mstore(0x260, add(mload(0x260), 1))

            // emit PairCreated(token0, token1, pair, allPairs.length);
            {
                mstore(0x300, pair)
                mstore(0x320, add(mload(0x260), 1))
                log3(
                    0x300,
                    0x40,
                    //event signature keccak256(PairCreated(address, address, address, uint256))
                    0x0d3648bd0f6ba80134a33ba9275ac585d9d315f0ad8355cddefde31afa28d0e9,
                    mload(0x100),
                    mload(0x120)
                )
            }
        }
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FACTORY:FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FACTORY:FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function addAllowed(address addr) external onlyRestricted {
        isAllowedCreator[addr] = true;
    }
}
