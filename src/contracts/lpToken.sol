//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {InterfaceLPToken} from "../interfaces/ILpToken.sol";

contract LPToken is InterfaceLPToken {
    address private _owner;
    string public constant name = "LiquidityProviderToken";
    string public constant symbol = "LP";
    uint8 public constant decimals = 18;

    uint256 public _totalSupply;
    uint256 public totalLockedLp;

    mapping(address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) _allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() {
        uint256 chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf[owner];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(
            _allowance[from][msg.sender] >= value,
            "LPTOKEN: TRANSFER_AMOUNT_EXCEED_ALLOWANCE"
        );
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        _totalSupply += value;
        _balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        _balanceOf[from] -= value;
        _totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = _allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "LPTOKEN: APPROVE_FROM_ZERO_AADRESS");
        require(
            spender != address(0),
            "LPTOKEN: SPENDER_CANNOT_BE_ADDRESS_ZERO"
        );
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(_balanceOf[from] >= value, "LPTOKEN: INSUFFICIENT_BALANCE");
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "LPTOKEN: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "LPTOKEN: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}
