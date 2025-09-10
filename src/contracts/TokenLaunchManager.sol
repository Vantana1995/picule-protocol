//SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.28;

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
import {ERC20} from "./erc20.sol";
import {ERC721Constructor} from "./erc721.sol";
import {ITokenLaunchManager} from "../interfaces/ITLmanager.sol";
import {FundsManager} from "./fundsManager.sol";

contract TokenLauncherManager is ITokenLaunchManager {
    address public icoManager;
    address public router;
    address public erc20Constructor;
    address public erc721Constructor;
    address public fundsManager;

    uint256 private projectNum;

    bool isInitialized = false;

    modifier _isInitialized() {
        require(isInitialized == false, "Contract already initialized");
        _;
        isInitialized = true;
    }

    constructor() {}

    function initializer(
        address _icoManager,
        address _router,
        address _erc20Implementation,
        address _erc721Implementation,
        address _FMImplementation
    ) external _isInitialized {
        icoManager = _icoManager;
        router = _router;
        erc20Constructor = _erc20Implementation;
        erc721Constructor = _erc721Implementation;
        fundsManager = _FMImplementation;
    }

    function createProject(
        string memory tokenName,
        string memory tokenSymbol,
        string memory erc721Name,
        string memory erc721Symbol,
        string memory baseURI,
        uint256 _maxSupplyERC721
    )
        external
        returns (
            address token,
            address erc721,
            address _fundsManager,
            uint256 icoID
        )
    {
        assembly {
            //require tokenName.length <= 32 bytes
            if gt(mload(tokenName), 32) {
                mstore(0x00, 0x36ee6969)
                revert(0x00, 0x04)
            }
            //require tokenSymbol.length <= 32 bytes
            if gt(mload(tokenSymbol), 32) {
                mstore(0x00, 0x92c9185d)
                revert(0x00, 0x04)
            }
            // require erc721Name.length <= 32 bytes
            if gt(mload(erc721Name), 32) {
                mstore(0x00, 0x1ad00117)
                revert(0x00, 0x04)
            }
            // require erc721Symbol.length <= 32bytes
            if gt(mload(erc721Symbol), 32) {
                mstore(0x00, 0x166c2c1d)
                revert(0x00, 0x04)
            }
            let _projectNum := sload(projectNum.slot)
            let icoContract := sload(icoManager.slot)
            let copy20 := sload(erc20Constructor.slot)
            let copy721 := sload(erc721Constructor.slot)
            let copyFM := sload(fundsManager.slot)
            let ptr := mload(0x40)
            // salt for erc20
            mstore(ptr, mload(add(tokenName, 0x20)))
            mstore(add(ptr, 0x20), mload(add(tokenSymbol, 0x20)))
            mstore(add(ptr, 0x40), _projectNum)
            // salt for creation
            mstore(add(ptr, 0x60), keccak256(ptr, 0x60))

            // cloneDeterinistic logic for erc20
            mstore(
                ptr,
                or(
                    shr(0xe8, shl(0x60, copy20)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            mstore(
                add(ptr, 0x20),
                or(shl(0x78, copy20), 0x5af43d82803e903d91602b57fd5bf3)
            )
            token := create2(0, add(ptr, 0x09), 0x37, mload(add(ptr, 0x60)))
            if iszero(token) {
                mstore(0x00, 0x8d3bde2a)
                revert(0x00, 0x04)
            }
            // salt  for erc721
            mstore(ptr, mload(add(erc721Name, 0x20)))
            mstore(add(ptr, 0x20), mload(add(erc721Symbol, 0x20)))
            mstore(add(ptr, 0x40), keccak256(ptr, 0x40))
            // cloneDeterinistic logic for erc721
            mstore(
                ptr,
                or(
                    shr(0xe8, shl(0x60, copy721)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            mstore(
                add(ptr, 0x20),
                or(shl(0x78, copy721), 0x5af43d82803e903d91602b57fd5bf3)
            )
            erc721 := create2(0, add(ptr, 0x09), 0x37, mload(add(ptr, 0x40)))
            if iszero(erc721) {
                mstore(0x00, 0x5ae4f94b)
                revert(0x00, 0x04)
            }
            // salt for fundsManager
            mstore(ptr, token)
            mstore(add(ptr, 0x20), erc721)
            mstore(add(ptr, 0x40), caller())
            mstore(add(ptr, 0x60), icoContract)
            mstore(add(ptr, 0x80), keccak256(ptr, 0x80))
            // colneDeterinistic logic for Fundsmanager
            mstore(
                ptr,
                or(
                    shr(0xe8, shl(0x60, copyFM)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            mstore(
                add(ptr, 0x20),
                or(shl(0x78, copyFM), 0x5af43d82803e903d91602b57fd5bf3)
            )
            _fundsManager := create2(
                0,
                add(ptr, 0x09),
                0x37,
                mload(add(ptr, 0x80))
            )
            if iszero(_fundsManager) {
                mstore(0x00, 0x618c12c4)
                revert(0x00, 0x04)
            }
            // initialization part
            // erc20
            mstore(ptr, shl(224, 0xdb0ed6a0))
            mstore(add(ptr, 0x04), 0xA0)
            mstore(add(ptr, 0x24), 0xE0)
            mstore(add(ptr, 0x44), icoContract)
            mstore(add(ptr, 0x64), sload(router.slot))
            mstore(add(ptr, 0x84), _fundsManager)
            mstore(add(ptr, 0xA4), mload(tokenName))
            mstore(add(ptr, 0xC4), mload(add(tokenName, 0x20)))
            mstore(add(ptr, 0xE4), mload(tokenSymbol))
            mstore(add(ptr, 0x104), mload(add(tokenSymbol, 0x20)))
            if iszero(call(gas(), token, 0, ptr, 0x124, 0x00, 0x00)) {
                mstore(0x00, 0x4d746e93)
                revert(0x00, 0x04)
            }
            // erc721
            mstore(ptr, shl(224, 0xe6a07063))
            mstore(add(ptr, 0x04), _maxSupplyERC721)
            mstore(add(ptr, 0x24), 0xA0)
            mstore(add(ptr, 0x44), 0xE0)
            mstore(add(ptr, 0x64), _fundsManager)
            mstore(add(ptr, 0x84), 0x120)
            mstore(add(ptr, 0xA4), mload(erc721Name))
            mstore(add(ptr, 0xC4), mload(add(erc721Name, 0x20)))
            mstore(add(ptr, 0xE4), mload(erc721Symbol))
            mstore(add(ptr, 0x104), mload(add(erc721Symbol, 0x20)))
            mstore(add(ptr, 0x124), caller())
            mstore(add(ptr, 0x144), mload(baseURI))
            for {
                let i := 0
            } lt(i, mload(baseURI)) {
                i := add(i, 0x20)
            } {
                mstore(
                    add(ptr, add(0x164, i)),
                    mload(add(add(baseURI, 0x20), i))
                )
            }
            mstore(0x00, add(0x124, mul(div(add(mload(baseURI), 31), 32), 32)))
            if iszero(call(gas(), erc721, 0, ptr, mload(0x00), 0x00, 0x00)) {
                mstore(0x00, 0xac833fde)
                revert(0x00, 0x04)
            }
            // fundsManager
            mstore(ptr, shl(224, 0x103524ab))
            mstore(add(ptr, 0x04), token)
            mstore(add(ptr, 0x24), erc721)
            mstore(add(ptr, 0x44), caller())
            mstore(add(ptr, 0x64), icoContract)
            if iszero(call(gas(), _fundsManager, 0, ptr, 0x84, 0x00, 0x00)) {
                mstore(0x00, 0xe6262400)
                revert(0x00, 0x04)
            }
            // createRequest(address,address,address,address)
            mstore(ptr, shl(224, 0xec37030e))
            mstore(add(ptr, 0x04), token)
            mstore(add(ptr, 0x24), erc721)
            mstore(add(ptr, 0x44), caller())
            mstore(add(ptr, 0x64), _fundsManager)
            if iszero(call(gas(), icoContract, 0, ptr, 0x84, ptr, 0x40)) {
                mstore(0x00, 0x152e25e2)
                revert(0x00, 0x04)
            }
            icoID := mload(ptr)

            sstore(projectNum.slot, add(_projectNum, 1))

            // prepair non-indexed data for event
            mstore(ptr, token)
            mstore(add(ptr, 0x20), erc721)
            mstore(add(ptr, 0x40), _fundsManager)
            mstore(add(ptr, 0x60), icoID)
            // emit ProjectCreated(address,address,address,address,uin256)
            log2(
                ptr,
                0x80,
                0xff065c0acc0b2f68f624394ee339b97978353ff8866625062c77c012bbbd4672,
                caller()
            )
            return(ptr, 0x80)
        }
    }
}
