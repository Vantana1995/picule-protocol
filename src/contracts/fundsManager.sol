//SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.30;

/*
 * Business Source License 1.1
 *
 * Parameters:
 * Licensor: 0x8b78EbA33460Ad98004dcE874e8Ed29cBd99EF98
 * Licensed Work: Picule Protocol Smart Contracts
 * Additional Use Grant: None
 * Change Date: August 12, 2028
 * Change License: MIT
 *
 * Commercial use, copying, modification, and distribution are prohibited
 * until the Change Date. After August 12, 2028, this code becomes
 * available under MIT License.
 */
import {InterfaceLPToken} from "../interfaces/ILpToken.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {Pair} from "./pair.sol";

contract FundsManager {
    address public icoManager;
    address public Factory;
    address public WMON;
    address public pair;

    address public token;
    address public erc721;
    address public manager;

    uint256 public totalLpLocked;
    uint256 public totalClaimedPacked;
    uint256 public checkpointNumber;
    uint256 public totalComission;
    uint256 public initialErc20Value = 10000000 * 1e18;
    uint private unlocked = 1;

    mapping(uint => uint) public checkpointAmountToReceive;
    mapping(uint => uint) tokenPerShareAtCheckpoint;
    mapping(uint tokenId => NFTData) nftReceiveData;

    struct NFTData {
        address user;
        uint256 checkpointClaimed;
        uint256 _numOfAdd;
        mapping(uint numOfAdd => uint256) checkpointLp;
        uint256 totalLpLockedByUser;
    }

    bool initialize = false;

    modifier initializer() {
        require(initialize == false, "Contract already initialized");
        _;
    }

    modifier _lock() {
        require(unlocked == 1, "Funds manager: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "ROUTER: EXPIRED");
        _;
    }

    event Checkpointupdate(
        address indexed erc721,
        uint newCheckpointNumber,
        uint checkPointAmountToReceivePacked,
        uint totalComission
    );

    event LPTokenLocked(
        address indexed lpProvider,
        address indexed lpToken,
        address indexed erc721,
        uint tokenId,
        uint lpLocked
    );

    event BonusClaimed(
        uint indexed tokenId,
        address indexed user,
        address indexed tokenClaimed,
        uint256 amount,
        uint256 checkpointFrom,
        uint256 checkpointTo
    );

    constructor() {}

    function setAddresses(address _factory, address _wmon) external {
        Factory = _factory;
        WMON = _wmon;
    }

    function initialization(
        address _erc20,
        address _erc721,
        address _manager,
        address _icoManager
    ) external initializer {
        token = _erc20;
        erc721 = _erc721;
        manager = _manager;
        icoManager = _icoManager;
        unlocked = 1;
    }

    receive() external payable {
        revert("USE_ENCODED_CALL");
    }

    fallback() external payable {
        assembly {
            // Ensure only the icoManager can call this function
            if iszero(eq(caller(), sload(icoManager.slot))) {
                mstore(0x20, 0x559c07bd)
                revert(0x00, 0x04)
            }

            // store in memory sotage data which will be used more than 1 time
            mstore(0x100, sload(WMON.slot))
            mstore(0x120, sload(token.slot))
            mstore(0x140, sload(erc721.slot))
            mstore(0x160, sload(manager.slot))
            mstore(0x180, sload(Factory.slot))
            mstore(0x1A0, sload(initialErc20Value.slot))

            // Convert ETH to WETH by calling deposit()
            {
                mstore(0x00, shl(224, 0xd0e30db0))
                if iszero(
                    call(gas(), mload(0x100), callvalue(), 0x00, 0x04, 0, 0)
                ) {
                    mstore(0x00, 0x87c73f0f)
                    revert(0x00, 0x04)
                }
            }

            // Call createPair(WETH, erc20) via Factory
            mstore(
                0x40,
                0xc9c6539600000000000000000000000000000000000000000000000000000000
            )
            mstore(0x44, mload(0x100))
            mstore(0x64, mload(0x120))
            if iszero(call(gas(), mload(0x180), 0, 0x40, 0x44, 0x40, 0x20)) {
                mstore(0xA0, 0x81e47d46)
                revert(0xA0, 0x04)
            }
            sstore(pair.slot, mload(0x40))
            mstore(0x1E0, mload(0x40))

            // Get and store function selector for transfer token
            mstore(0x40, shl(224, 0xa9059cbb))
            mstore(0x44, mload(0x1E0))

            // transfer WETH  to pair
            mstore(0x64, callvalue())
            if iszero(call(gas(), mload(0x100), 0, 0x40, 0x44, 0, 0)) {
                mstore(0xA0, 0x1e7074ab)
                revert(0xA0, 0x04)
            }
            // transfer erc20 to pair
            mstore(0x64, mload(0x1A0))
            if iszero(call(gas(), mload(0x120), 0, 0x40, 0x44, 0, 0)) {
                revert(0, 0)
            }

            mstore(
                0x40,
                0x6a62784200000000000000000000000000000000000000000000000000000000
            )
            mstore(0x44, address())
            if iszero(call(gas(), mload(0x1E0), 0, 0x40, 0x24, 0x40, 0x20)) {
                revert(0, 0)
            }
            // store lpValue
            mstore(0x1C0, mload(0x40))

            // lock LP token
            mstore(
                0x40,
                0x282d3fdf00000000000000000000000000000000000000000000000000000000
            )
            mstore(0x44, address())
            mstore(0x64, mload(0x1C0))
            if iszero(call(gas(), mload(0x1E0), 0, 0x40, 0x44, 0, 0)) {
                mstore(0xA0, 0x7602fc7c)
                revert(0xA0, 0x04)
            }

            // safeMint NFT to manager
            mstore(
                0x40,
                0x40d097c300000000000000000000000000000000000000000000000000000000
            )
            mstore(0x44, mload(0x160))
            if iszero(call(gas(), mload(0x140), 0, 0x40, 0x24, 0x40, 0x20)) {
                mstore(0xA0, 0xa2e2ac5b)
                revert(0xA0, 0x04)
            }

            // sstore all data
            sstore(totalLpLocked.slot, mload(0x1C0))

            // mapping(uint tokenId => ToReceive) nftReceiveData;
            mstore(0x00, mload(0x40))
            mstore(0x20, nftReceiveData.slot)
            mstore(0x60, keccak256(0x00, 0x40))
            // sstore data in struct user
            sstore(mload(0x60), mload(0x160))
            // store _numOfAdd
            sstore(add(mload(0x60), 2), 1)
            // store totalLpLockedByUser
            sstore(add(mload(0x60), 4), mload(0x1C0))
            // calculate inner mapping slot
            mstore(0x00, 1)
            mstore(0x20, add(mload(0x60), 3))
            mstore(0x60, keccak256(0x00, 0x40))
            sstore(mload(0x60), or(shl(128, 1), mload(0x1C0)))
            sstore(checkpointNumber.slot, 1)

            // event LPTokenLocked
            mstore(0x00, mload(0x40))
            mstore(0x20, mload(0x1C0))
            log4(
                0x00,
                0x40,
                0x7aba7577acda76de23b799292a5f95268536fa3368ec5afafde1fac9f880caa5,
                mload(0x160),
                mload(0x1E0),
                mload(0x140)
            )
        }
    }

    function claimBonus(
        address nftAddress,
        uint256 tokenId,
        uint deadline
    ) external ensure(deadline) {
        assembly {
            // Revert if nftAddress is zero
            if iszero(nftAddress) {
                mstore(0x00, 0x96fff706)
                revert(0x00, 0x04)
            }
            // address for struct
            mstore(0x00, tokenId)
            mstore(0x20, nftReceiveData.slot)
            mstore(0x100, keccak256(0x00, 0x40))
            // require msg.sender is ownerOf tokenId
            if iszero(eq(caller(), sload(mload(0x100)))) {
                mstore(0xA0, 0xa1b4fc09)
                revert(0xA0, 0x04)
            }
            // check if actual checkpoint is more that claimed checkpoint
            mstore(0x180, sload(checkpointNumber.slot))
            // last checkpoint claimed
            mstore(0x1A0, sload(add(mload(0x100), 1)))
            if iszero(lt(mload(0x1A0), mload(0x180))) {
                mstore(0xA0, 0x0845f1e7)
                revert(0xA0, 0x04)
            }

            mstore(0x00, sload(token.slot))
            mstore(0x20, sload(WMON.slot))
            mstore(0x120, mload(0x00))
            mstore(0x140, mload(0x20))
            // Determine token order  token0 and token1
            if gt(mload(0x120), mload(0x140)) {
                mstore(0x120, mload(0x20))
                mstore(0x140, mload(0x00))
            }
            // uint256 _numOfAdd;
            mstore(0x1C0, sload(add(mload(0x100), 2)))
            mstore(0x00, mload(0x1C0))
            mstore(0x20, add(mload(0x100), 3))
            mstore(0x40, keccak256(0x00, 0x40))

            //  checkpointLp Packed
            mstore(0x1E0, sload(mload(0x40)))
            //checkpointWhenUpdated
            mstore(0x200, shr(128, mload(0x1E0)))
            // lpToken at checkpointWhenUpdate
            mstore(0x220, and(mload(0x1E0), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // value in token
            mstore(0x240, 0) // token0
            mstore(0x260, 0) // token1
            for {
                let cp := mload(0x180)
            } gt(cp, mload(0x1A0)) {
                cp := sub(cp, 1)
            } {
                // tokenPerShareAtCheckpont[cp]
                mstore(0x00, cp)
                mstore(0x20, tokenPerShareAtCheckpoint.slot)
                mstore(0x280, sload(keccak256(0x00, 0x40))) // tokenPerSharePacked
                // unpacked tokenPerShare
                mstore(0x40, shr(128, mload(0x280))) // tps0
                mstore(
                    0x60,
                    and(mload(0x280), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                ) // tps1
                // token at this checkpoint
                mstore(0x80, mul(mload(0x220), mload(0x40))) // token0AtCheckpoint
                mstore(0xA0, mul(mload(0x220), mload(0x60))) // token1AtCheckpoint
                mstore(0x240, add(mload(0x240), mload(0x80))) // newToken0
                mstore(0x260, add(mload(0x260), mload(0xA0))) // newToken1

                if lt(cp, mload(0x200)) {
                    mstore(0x1C0, sub(mload(0x1C0), 1))
                    if iszero(mload(0x1C0)) {
                        break
                    }
                    mstore(0x00, mload(0x1C0))
                    mstore(0x20, add(mload(0x100), 3))
                    mstore(0x40, keccak256(0x00, 0x40))
                    //new checkpointLpPacked
                    mstore(0x1E0, sload(mload(0x40)))
                    // new checkpointWhenUpdated
                    mstore(0x200, shr(128, mload(0x1E0)))
                    // new lpToken at checkpointWhenUpdate
                    mstore(
                        0x220,
                        and(mload(0x1E0), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    )
                }
            }
            mstore(0x240, div(mload(0x240), 1000000000000000000)) // token0
            mstore(0x260, div(mload(0x260), 1000000000000000000)) // token1

            // transfer tokens
            mstore(0x00, shl(224, 0x23b872dd))
            mstore(0x04, sload(pair.slot))
            mstore(0x24, caller())
            mstore(0x44, mload(0x240))
            if iszero(call(gas(), mload(0x120), 0, 0x00, 0x64, 0x00, 0x00)) {
                mstore(0xA0, 0x40432422)
                revert(0xA0, 0x04)
            }
            mstore(0x44, mload(0x260))
            if iszero(call(gas(), mload(0x140), 0, 0x00, 0x64, 0x00, 0x00)) {
                mstore(0xA0, 0x029172a6)
                revert(0xA0, 0x04)
            }
            // sync()
            mstore(0x40, shl(224, 0xfff6cae9))
            if iszero(call(gas(), mload(0x04), 0, 0x40, 0x04, 0x00, 0x00)) {
                mstore(0xA0, 0x25053ef5)
                revert(0xA0, 0x04)
            }
            // update totalClaimed
            mstore(0x00, sload(totalClaimedPacked.slot))
            //  oldTotalClaimed0
            mstore(0x20, shr(128, mload(0x00)))
            //  oldTotalClaimed1
            mstore(0x40, and(mload(0x00), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // new totalClaimed0
            mstore(0x20, add(mload(0x20), mload(0x240)))
            mstore(0x40, add(mload(0x40), mload(0x260)))
            // wrap new totalClaimed
            mstore(0x00, or(shl(128, mload(0x20)), mload(0x40)))
            sstore(totalClaimedPacked.slot, mload(0x00))
            // update checkpointClaimed in struct
            sstore(add(mload(0x100), 2), mload(0x180))

            // event BonusClaimed for token0
            mstore(0x00, mload(0x240))
            mstore(0x20, mload(0x1A0))
            mstore(0x40, mload(0x180))
            log4(
                0x00,
                0x60,
                0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                tokenId,
                caller(),
                mload(0x120)
            )
            // event BonusClaimed for token1
            mstore(0x00, mload(0x260))
            log4(
                0x00,
                0x60,
                0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                tokenId,
                caller(),
                mload(0x140)
            )
            sstore(unlocked.slot, 1)
        }
    }

    function managerClaim(
        address nftAddress,
        uint256 tokenId,
        uint deadline
    ) external ensure(deadline) {
        assembly {
            // not from this project
            if iszero(eq(sload(erc721.slot), nftAddress)) {
                mstore(0xA0, 0x64afb0e6)
                revert(0xA0, 0x04)
            }
            let _manager := sload(manager.slot)
            if iszero(eq(_manager, caller())) {
                mstore(0xA0, 0xbe021242)
                revert(0xA0, 0x04)
            }
            let _pair := sload(pair.slot)
            mstore(0x00, tokenId)
            mstore(0x20, nftReceiveData.slot)
            // struct
            mstore(0x100, keccak256(0x00, 0x40))
            // require msg.sender is ownerOf tokenId
            if iszero(eq(caller(), sload(mload(0x100)))) {
                mstore(0xA0, 0xd8964296)
                revert(0xA0, 0x04)
            }
            mstore(0x120, sload(checkpointNumber.slot))
            mstore(0x140, sload(add(mload(0x100), 1)))
            // check if actual checkpoint is more that claimed checkpoint
            if iszero(lt(mload(0x140), mload(0x120))) {
                mstore(0xA0, 0xb3fa726c)
                revert(0xA0, 0x04)
            }
            // uint256 _numOfAdd;
            mstore(0x160, sload(add(mload(0x100), 2)))
            // mapping(uint numOfAdd => uint256) checkpointLp
            mstore(0x00, mload(0x160))
            mstore(0x20, add(mload(0x100), 3))
            mstore(0x40, keccak256(0x00, 0x40))
            //  checkpointLp Packed
            mstore(0x180, sload(mload(0x40)))
            //checkpointWhenUpdated
            mstore(0x1A0, shr(128, mload(0x180)))
            // lpToken at checkpointWhenUpdate
            mstore(0x1C0, and(mload(0x180), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // value in token
            mstore(0x1E0, 0)
            mstore(0x200, 0)
            for {
                let cp := mload(0x120)
            } gt(cp, mload(0x140)) {
                cp := sub(cp, 1)
            } {
                // tokenPerShareAtCheckpont[cp]
                mstore(0x00, cp)
                mstore(0x20, tokenPerShareAtCheckpoint.slot)
                mstore(0x40, sload(keccak256(0x00, 0x40))) // tokenPerSharePacked
                // unpack tokenPerShare
                mstore(0x60, shr(128, mload(0x40))) // tps0
                mstore(
                    0x80,
                    and(mload(0x40), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                ) // tps1
                // tokenAtThisCheckpoint
                mstore(0xA0, mul(mload(0x1C0), mload(0x60))) // token0AtCheckpoint
                mstore(0xC0, mul(mload(0x1C0), mload(0x80))) // token1AtCheckpoint
                mstore(0x1E0, add(mload(0x1E0), mload(0xA0))) // token0New
                mstore(0x200, add(mload(0x200), mload(0xC0))) // token1New

                if lt(cp, mload(0x1A0)) {
                    mstore(0x160, sub(mload(0x160), 1))
                    if iszero(mload(0x160)) {
                        break
                    }
                    mstore(0x00, mload(0x160))
                    mstore(0x20, add(mload(0x100), 3))
                    mstore(0x40, keccak256(0x00, 0x40))
                    // newCheckpointLpPacked
                    mstore(0x180, sload(mload(0x40)))
                    // newCheckpointWhenUpdate
                    mstore(0x1A0, shr(128, mload(0x180)))
                    // newLpTokenAtCheckpointUdate
                    mstore(
                        0x1C0,
                        and(mload(0x180), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    )
                }
            }
            mstore(0x1E0, div(mload(0x1E0), 1000000000000000000))
            mstore(0x200, div(mload(0x200), 1000000000000000000))
            // Determine token order  token0 and token1
            mstore(0x00, sload(token.slot))
            mstore(0x20, sload(WMON.slot))
            mstore(0x220, mload(0x00))
            mstore(0x240, mload(0x20))

            if gt(mload(0x220), mload(0x240)) {
                mstore(0x220, mload(0x20))
                mstore(0x240, mload(0x00))
            }
            // determine where is WETH token/ 1 in 0x260 if weth -token0
            mstore(0x260, 0)
            if eq(mload(0x220), mload(0x20)) {
                mstore(0x260, 1)
            }

            switch mload(0x260)
            case 1 {
                mstore(0x00, mload(0x1E0)) // token0Value
                mstore(0x20, mload(0x200)) // token1Value
            }
            default {
                mstore(0x220, mload(0x240)) // addressWETH
                mstore(0x240, mload(0x00)) // tokenERC
                mstore(0x00, mload(0x200)) // token1Value
                mstore(0x20, mload(0x1E0)) // token0Value
            }

            // bool logic
            // allTokenMinted  ?
            mstore(0x40, shl(224, 0x436afe32))
            if iszero(staticcall(gas(), mload(0x240), 0x40, 0x04, 0x40, 0x20)) {
                mstore(0xA0, 0xf76dccfc)
                revert(0xA0, 0x04)
            }
            // all token minted flag in 0x40
            let allTokenMinted := mload(0x40)
            if iszero(allTokenMinted) {
                // mint + addLiquidity
                // amountWETH to addLiquidity

                mstore(0xC0, div(mload(0x00), 2))

                // prepare for transferFrom
                mstore(0x40, shl(224, 0x23b872dd))
                mstore(0x44, _pair)
                mstore(0x64, address())
                // weth
                mstore(0x84, mload(0x00))
                if iszero(
                    call(gas(), mload(0x220), 0, 0x40, 0x64, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0xf5305260)
                    revert(0xA0, 0x04)
                }
                // erc20
                mstore(0x64, caller())
                mstore(0x84, mload(0x20))
                if iszero(
                    call(gas(), mload(0x240), 0, 0x40, 0x64, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0x82c64013)
                    revert(0xA0, 0x04)
                }
                // sync()
                mstore(0x40, shl(224, 0xfff6cae9))
                if iszero(call(gas(), _pair, 0, 0x40, 0x04, 0x00, 0x00)) {
                    mstore(0xA0, 0x6db5a1d0)
                    revert(0xA0, 0x04)
                }
                // lock()
                mstore(0x40, shl(224, 0xf83d08ba))
                if iszero(call(gas(), _pair, 0, 0x40, 0x04, 0x00, 0x00)) {
                    mstore(0xA0, 0xb0e40c99)
                    revert(0xA0, 0x04)
                }
                // getReserves()
                mstore(0x40, shl(224, 0x0902f1ac))
                if iszero(staticcall(gas(), _pair, 0x40, 0x04, 0x40, 0x40)) {
                    mstore(0xA0, 0x7a3df020)
                    revert(0xA0, 0x04)
                }
                let reserve0 := mload(0x40)
                let reserve1 := mload(0x60)
                let toMint
                switch mload(0x260)
                case 1 {
                    toMint := div(mul(mload(0xC0), reserve0), reserve1)
                }
                default {
                    toMint := div(mul(mload(0xC0), reserve1), reserve0)
                }
                if iszero(toMint) {
                    revert(0, 0)
                }
                // call mint erc20Token to pair Address
                mstore(0x40, shl(224, 0x40c10f19))
                mstore(0x44, _pair)
                mstore(0x64, toMint)
                if iszero(
                    call(gas(), mload(0x240), 0, 0x40, 0x44, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0xe675819b)
                    revert(0xA0, 0x04)
                }
                // transfer weth to pair address
                mstore(0x40, shl(224, 0xa9059cbb))
                mstore(0x44, _pair)
                mstore(0x64, mload(0xC0))
                if iszero(
                    call(gas(), mload(0x220), 0, 0x40, 0x44, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0xf170786b)
                    revert(0xA0, 0x04)
                }
                // transfer WETH to manager
                mstore(0x44, _manager)
                mstore(0x64, sub(mload(0x00), mload(0xC0)))
                if iszero(
                    call(gas(), mload(0x220), 0, 0x40, 0x44, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0x8ab6ccce)
                    revert(0xA0, 0x04)
                }
                // unlock(address)  0xE0 lpToken
                mstore(0x40, shl(224, 0x2f6c493c))
                mstore(0x44, address())
                if iszero(call(gas(), _pair, 0, 0x40, 0x24, 0xE0, 0x20)) {
                    mstore(0xA0, 0x83c36438)
                    revert(0xA0, 0x04)
                }
                // lockLp token to manager
                mstore(0x40, shl(224, 0x282d3fdf))
                mstore(0x44, _manager)
                mstore(0x64, mload(0xE0))
                if iszero(call(gas(), _pair, 0, 0x40, 0x44, 0x00, 0x00)) {
                    mstore(0xA0, 0x2641205f)
                    revert(0xA0, 0x04)
                }
                // totalLpLocked += amount
                sstore(
                    totalLpLocked.slot,
                    add(sload(totalLpLocked.slot), mload(0xE0))
                )
                // totalLpLockedByUser += amount
                sstore(
                    add(mload(0x100), 4),
                    add(sload(add(mload(0x100), 4)), mload(0xE0))
                )
                // updateBonus(address erc721)
                mstore(0x40, shl(224, 0x983c8fa9))
                mstore(0x44, nftAddress)
                if iszero(call(gas(), address(), 0, 0x40, 0x24, 0x00, 0x00)) {
                    mstore(0xA0, 0x8d009c94)
                    revert(0xA0, 0x04)
                }
                // prepair non-indexed data for event log
                mstore(0x40, tokenId)
                mstore(0x60, mload(0xE0))
                log4(
                    0x00,
                    0x40,
                    0x7aba7577acda76de23b799292a5f95268536fa3368ec5afafde1fac9f880caa5,
                    caller(),
                    _pair,
                    nftAddress
                )
            }
            // all token minted true
            if eq(allTokenMinted, 1) {
                // require burnLimit not excseed
                mstore(0x40, shl(224, 0x92a2274f))
                if iszero(
                    staticcall(gas(), mload(0x240), 0x40, 0x04, 0xC0, 0x20)
                ) {
                    mstore(0xA0, 0x06726994)
                    revert(0xA0, 0x04)
                }
                // prepare for transferFrom
                // weth to manager
                mstore(0x40, shl(224, 0x23b872dd))
                mstore(0x44, _pair)
                mstore(0x64, _manager)
                mstore(0x84, mload(0x00))
                if iszero(
                    call(gas(), mload(0x220), 0, 0x40, 0x64, 0x00, 0x00)
                ) {
                    mstore(0xA0, 0xdb73ea7e)
                    revert(0xA0, 0x04)
                }
                switch mload(0xC0)
                case 1 {
                    // erc20 to manager
                    mstore(0x84, mload(0x20))
                    if iszero(
                        call(gas(), mload(0x240), 0, 0x40, 0x64, 0x00, 0x00)
                    ) {
                        mstore(0xA0, 0xa2190460)
                        revert(0xA0, 0x04)
                    }
                }
                default {
                    // logic for burn token
                    // erc20 to address(this)
                    mstore(0x64, address())
                    mstore(0x84, mload(0x20))
                    if iszero(
                        call(gas(), mload(0x240), 0, 0x40, 0x64, 0x00, 0x00)
                    ) {
                        mstore(0xA0, 0x18f7302a)
                        revert(0xA0, 0x04)
                    }
                    // burn token
                    mstore(0x40, shl(224, 0x42966c68))
                    mstore(0x44, mload(0x20))
                    if iszero(
                        call(gas(), mload(0x240), 0, 0x40, 0x24, 0x00, 0x00)
                    ) {
                        mstore(0xA0, 0xe1a64cf5)
                        revert(0xA0, 0x04)
                    }
                }
                // sync()
                mstore(0x40, shl(224, 0xfff6cae9))
                if iszero(call(gas(), _pair, 0, 0x40, 0x04, 0x00, 0x00)) {
                    mstore(0xA0, 0x234a0292)
                    revert(0xA0, 0x04)
                }
            }
            // oldTotalClaimed
            mstore(0x00, sload(totalClaimedPacked.slot))
            // oldTotalClaimed0
            mstore(0x20, shr(128, mload(0x00)))
            // oldTotalClaimed1
            mstore(0x40, and(mload(0x00), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            // newTotalClaimed0
            mstore(0x00, add(mload(0x1E0), mload(0x20)))
            // newTotalClaimed1
            mstore(0x20, add(mload(0x200), mload(0x40)))
            // wrap newTotalClaimed
            mstore(0x40, or(shl(128, mload(0x00)), mload(0x20)))
            // store newTotalClaimed
            sstore(totalClaimedPacked.slot, mload(0x40))
            // store newChecpointClaimed
            sstore(add(mload(0x100), 1), mload(0x120))

            // event BonusClaimed for token0
            mstore(0x20, mload(0x140))
            mstore(0x40, mload(0x120))
            switch mload(0x260)
            case 1 {
                mstore(0x00, mload(0x1E0))
                log4(
                    0x00,
                    0x60,
                    0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                    tokenId,
                    _manager,
                    mload(0x220)
                )
                mstore(0x00, mload(0x200))
                log4(
                    0x00,
                    0x60,
                    0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                    tokenId,
                    _manager,
                    mload(0x240)
                )
            }
            default {
                mstore(0x00, mload(0x200))
                log4(
                    0x00,
                    0x60,
                    0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                    tokenId,
                    _manager,
                    mload(0x220)
                )
                mstore(0x00, mload(0x1E0))
                log4(
                    0x00,
                    0x60,
                    0x7bf7bdcfb9fcf3aa908da73fad3a2052cb9d9a221d52ec6c5eed9d3ba58b12e2,
                    tokenId,
                    _manager,
                    mload(0x240)
                )
            }
            sstore(unlocked.slot, 1)
        }
    }

    function lockLp(uint256 amount) external _lock returns (uint256 tokenId) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, sload(totalLpLocked.slot))
            mstore(ptr, div(mul(mload(ptr), 1), 100))
            // Require amount >= 1% of totalLpLocked (minimum threshold)
            if lt(amount, mload(ptr)) {
                mstore(0x160, 0x1c4f7a95) // Custom error: INSUFFICIENT_AMOUNT
                revert(0x160, 0x04)
            }
            // store in memory lpToken address
            let _pair := sload(pair.slot)
            mstore(0x40, shl(224, 0xcca3e832))
            mstore(0x44, caller())
            if iszero(staticcall(gas(), _pair, 0x40, 0x24, 0x120, 0x20)) {
                mstore(0x160, 0x4211d086)
                revert(0x160, 0x04)
            }
            // require balanceOf > amount
            if lt(mload(0x120), amount) {
                mstore(0x160, 0x3d2e3589)
                revert(0x160, 0x04)
            }
            //store in memory erc721 address
            mstore(0x140, sload(erc721.slot))
            // require erc721.balanceOf(msg.sender) == 0
            if iszero(staticcall(gas(), 0x140, 0x40, 0x24, 0x00, 0x20)) {
                mstore(0x160, 0xe728e5ad)
                revert(0x160, 0x04)
            }
            if mload(0x00) {
                mstore(0x160, 0x8355a3ad)
                revert(0x160, 0x04)
            }
            // lockLp token to msg.sender
            mstore(0x40, shl(224, 0x282d3fdf))
            mstore(0x44, caller())
            mstore(0x64, amount)
            if iszero(call(gas(), _pair, 0, 0x40, 0x44, 0x00, 0x00)) {
                mstore(0x160, 0x9971af4d)
                revert(0x160, 0x04)
            }
            // safeMint nft to msg.sender
            mstore(0x40, shl(224, 0x40d097c3))
            mstore(0x44, caller())
            if iszero(call(gas(), mload(0x140), 0, 0x40, 0x24, 0x00, 0x20)) {
                mstore(0x160, 0x60b74678)
                revert(0x160, 0x04)
            }
            tokenId := mload(0x00)
            // totalLpLocked += amount
            sstore(totalLpLocked.slot, add(sload(totalLpLocked.slot), amount))

            // store data in  mapping(uint tokenId => NFTData) nftReceiveData;
            mstore(0x00, tokenId)
            mstore(0x20, nftReceiveData.slot)
            mstore(0x40, keccak256(0x00, 0x40))
            sstore(mload(0x40), caller())
            sstore(add(mload(0x40), 2), 1)
            // calculate inner mapping slot
            mstore(0x00, 1)
            mstore(0x20, add(mload(0x40), 3))
            mstore(0x40, keccak256(0x00, 0x40))
            sstore(
                mload(0x40),
                or(shl(128, add(sload(checkpointNumber.slot), 1)), amount)
            )

            // updateBonus(address erc721)
            mstore(0x40, shl(224, 0x983c8fa9))
            mstore(0x44, mload(0x140))
            if iszero(call(gas(), address(), 0, 0x40, 0x24, 0x00, 0x00)) {
                mstore(0x160, 0x6db15197)
                revert(0x160, 0x04)
            }

            // prepair non-indexed data for event log
            mstore(0x00, tokenId)
            mstore(0x20, amount)
            log4(
                0x00,
                0x40,
                0x7aba7577acda76de23b799292a5f95268536fa3368ec5afafde1fac9f880caa5,
                caller(),
                _pair,
                mload(0x140)
            )
            sstore(unlocked.slot, 1)
            return(0x00, 0x20)
        }
    }

    function addLpToNFT(uint256 tokenId, uint256 amount) external _lock {
        assembly {
            let ptr := mload(0x40)
            // Calculate 1% of totalLpLocked as minimum threshold
            mstore(ptr, sload(totalLpLocked.slot))
            mstore(ptr, div(mul(mload(ptr), 1), 100))
            // Require amount >= 1% of totalLpLocked (minimum threshold)
            if lt(amount, mload(ptr)) {
                mstore(0x160, 0x1c4f7a95) // Custom error: INSUFFICIENT_AMOUNT
                revert(0x160, 0x04)
            }
            mstore(0x00, tokenId)
            mstore(0x20, nftReceiveData.slot)
            mstore(0x120, keccak256(0x00, 0x40))
            if iszero(eq(caller(), sload(mload(0x120)))) {
                mstore(0x160, 0x6a3a8bd8)
                revert(0x160, 0x04)
            }
            mstore(0x100, sload(pair.slot))
            mstore(0x40, shl(224, 0x70a08231))
            mstore(0x44, caller())
            if iszero(staticcall(gas(), mload(0x100), 0x40, 0x24, 0x00, 0x20)) {
                mstore(0x160, 0xb9142078)
                revert(0x160, 0x04)
            }
            // require balanceOf >= amount
            if lt(mload(0x00), amount) {
                mstore(0x140, 0x8850eb3b)
                revert(0x140, 0x04)
            }
            // lockLp token to msg.sender
            mstore(0x40, shl(224, 0x282d3fdf))
            mstore(0x44, caller())
            mstore(0x64, amount)
            if iszero(call(gas(), mload(0x100), 0, 0x40, 0x44, 0x00, 0x00)) {
                mstore(0x160, 0x0dc6ed18)
                revert(0x160, 0x04)
            }
            // totalLpLocked += amount
            sstore(totalLpLocked.slot, add(sload(totalLpLocked.slot), amount))
            mstore(0x00, add(sload(add(mload(0x120), 2)), 1))
            sstore(add(mload(0x120), 2), mload(0x00))
            mstore(0x20, add(mload(0x120), 3))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, add(sload(add(mload(0x120), 4)), amount))
            sstore(add(mload(0x120), 4), mload(0x20))
            // packed checkpointLp
            mstore(
                0x40,
                or(shl(128, add(sload(checkpointNumber.slot), 1)), mload(0x20))
            )
            sstore(mload(0x00), mload(0x40))
            // updateBonus(address erc721)
            mstore(0x40, shl(224, 0x983c8fa9))
            mstore(0x44, sload(erc721.slot))
            if iszero(call(gas(), address(), 0, 0x40, 0x24, 0x00, 0x00)) {
                mstore(0x140, 0x81fff75b)
                revert(0x140, 0x04)
            }
            // prepair non-indexed data for event log
            mstore(0x00, tokenId)
            mstore(0x20, amount)
            log4(
                0x00,
                0x40,
                0x7aba7577acda76de23b799292a5f95268536fa3368ec5afafde1fac9f880caa5,
                caller(),
                mload(0x100),
                mload(0x120)
            )
            sstore(unlocked.slot, 1)
        }
    }

    function updateBonus(address nftAddress) external {
        assembly {
            // require to only internal calls
            if iszero(eq(caller(), address())) {
                mstore(0x240, 0x60259cc3)
                revert(0x240, 0x04)
            }

            // totalClaimed packed
            mstore(0x100, sload(totalClaimedPacked.slot))
            // checkpointNumber
            mstore(0x120, sload(checkpointNumber.slot))
            // call _binaryComission form pair contract
            mstore(0x00, shl(224, 0xb16523b4))
            if iszero(
                staticcall(gas(), sload(pair.slot), 0x00, 0x04, 0x00, 0x40)
            ) {
                mstore(0x240, 0x22354aa9)
                revert(0x240, 0x04)
            }
            // unpacked comission
            mstore(0x140, mload(0x00)) // comission0
            mstore(0x160, mload(0x20)) // comission1

            // unpacked totalClaimed comission
            mstore(0x180, shr(128, mload(0x100))) // totalClaimed0
            mstore(0x1A0, and(mload(0x100), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) // totalClaimed1
            // calculate totalComission
            mstore(0x00, 0)
            mstore(0x20, 0)
            mstore(0x00, add(mload(0x140), mload(0x180))) // totalComission0
            mstore(0x20, add(mload(0x160), mload(0x1A0))) // totalComission1
            // load oldTotalComission
            mstore(0x40, sload(totalComission.slot)) // totalComissionPacked
            // unpacked oldTotalComission
            mstore(0x1C0, shr(128, mload(0x40))) // totalComission0
            mstore(0x1E0, and(mload(0x40), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) // totalComission1
            // calculate checkpointAmountToReceive = totalComission - oldTotalComisiion
            mstore(0x40, 0)
            mstore(0x40, sub(mload(0x00), mload(0x1C0))) // checkpointAmountToReceive0
            mstore(0x60, sub(mload(0x20), mload(0x1E0))) // checkpointAmountToReceive1
            // new packedTotalComission
            mstore(0x200, or(shl(128, mload(0x00)), mload(0x20)))
            // checkpointAmountToReceivePacked
            mstore(0x220, or(shl(128, mload(0x40)), mload(0x60)))
            // total lpLocked
            mstore(0x00, 0)

            // добавить 18 степень для деления
            mstore(0x00, sload(totalLpLocked.slot))
            //calcultate tokenPerShareAtCheckpoint
            mstore(
                0x20,
                div(mul(mload(0x40), 1000000000000000000), mload(0x00))
            ) // tokenPerShareAtCheckpoint0
            mstore(
                0x40,
                div(mul(mload(0x60), 1000000000000000000), mload(0x00))
            ) // tokenPerShareAtCheckpoint1
            // tokePerShareAtCheckpointPacked
            mstore(0x00, or(shl(128, mload(0x20)), mload(0x40)))
            // prepair mapping address
            mstore(0x40, mload(0x120))
            // store checkpointNumber for mapping addresses
            mstore(0x60, checkpointAmountToReceive.slot)
            // store mapping(uint => uint) checkpointAmountToReceive
            sstore(keccak256(0x40, 0x40), mload(0x220))
            mstore(0x60, tokenPerShareAtCheckpoint.slot)
            // store mapping(uint => uint) tokenPerShareAtCheckpoint
            sstore(keccak256(0x40, 0x40), mload(0x00))
            // store newTotalComission
            sstore(totalComission.slot, mload(0x200))
            // store checkpointNumber
            sstore(checkpointNumber.slot, add(mload(0x120), 1))

            // prepair non-indexed data for event
            mstore(0x00, add(mload(0x120), 1))
            mstore(0x20, mload(0x220))
            mstore(0x40, mload(0x200))
            log2(
                0x00,
                0x60,
                0xa4ad32f6057378f52e13605d6fe10b359f2a22c576981530bc9a4469fdeff37a,
                nftAddress
            )
        }
    }
}
