//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "../interfaces/IERC20.sol";

abstract contract ERC20Constructor is IERC20 {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public totalBurned;
    uint256 private constant MAX_SUPPLY = 10000000000000 * 10 ** 18;
    uint256 private constant BURN_LIMIT = 2000000000000 * 10 ** 18;

    bool public allTokenMinted = false;
    bool private burnLimit = false;
    bool private initialized;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    mapping(address account => uint256) public override balanceOf;
    mapping(address account => mapping(address spender => uint256))
        public allowance;

    modifier initializer() {
        require(!initialized, "Contract is already initialized");
        _;
    }

    constructor() {}

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        name = _name;
        symbol = _symbol;
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

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(
            balanceOf[msg.sender] >= value,
            "ERC20: Not enough token to transfer"
        );
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        require(balanceOf[from] >= value, "ERC20: Not emought token");
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) public virtual returns (bool) {
        require(
            allTokenMinted == false,
            "ERC20: You can`t mint more token after mint phase is finish"
        );
        require(to != address(0), "ERC20: Burn function for this");
        _update(address(0), to, value);
        if (totalSupply > MAX_SUPPLY) {
            allTokenMinted = true;
        }
        return true;
    }

    function burn(uint256 value) external returns (bool) {
        require(
            allTokenMinted == true,
            "ERC20: You can`t burn token before mint is finish"
        );
        require(balanceOf[msg.sender] >= value, "ERC20: Not enough token");
        _update(msg.sender, address(0), value);
        if (totalBurned > BURN_LIMIT) {
            burnLimit = true;
        }
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
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
        require(deadline >= block.timestamp, "ERC20: EXPIRED");
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
            "ERC20: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: Invalid receiver");
        require(from != address(0), "ERC20: Invalid sender");
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            totalSupply += value;
        } else {
            uint256 fromBalance = balanceOf[from];
            if (fromBalance < value) {
                revert("ERC20: Not enought token");
            }
            unchecked {
                balanceOf[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                totalSupply -= value;
                totalBurned += value;
            }
        } else {
            unchecked {
                balanceOf[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: Invalid owner");
        require(spender != address(0), "ERC20: Invalid spender");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= value, "ERC20: Not enough allowance");
        if (currentAllowance != type(uint256).max) {
            unchecked {
                _approve(owner, spender, currentAllowance - value);
            }
        }
    }
}
