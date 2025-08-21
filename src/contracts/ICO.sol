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

import {IERC20} from "../interfaces/IERC20.sol";
import {Transfer} from "../libraries/TransferLib.sol";
import {IICO} from "../interfaces/IICO.sol";

contract ICO is IICO {
    address public owner;
    address public MPC;
    address public immutable NFT;
    address public fundsManager;
    address public tlm;
    address public factory;
    uint public numOfRequests;
    uint private unlocked = 1;

    bool initialized = false;

    mapping(uint => Request) public requests;

    struct Request {
        address ercToken; //0
        address erc721; //1
        address manager; //2
        address fundsManager_; //3
        uint target; //4
        uint deadline; //5
        uint minimum; //6
        uint value; //7
        uint raised; //8
        bool completed; //9
        mapping(address => uint) contributors; //10
        uint numOfContributors; // 11
        mapping(uint => address) addressOfContributor; // 12
    }

    modifier _lock() {
        require(unlocked == 1, "Pair : LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyInitialized() {
        require(initialized == true, "CROWDFOUNDING: NOT_ACTIVATED");
        _;
    }

    event RequestCreated(uint indexed numOfRequest);
    event Contributed(
        uint256 indexed numOfProject,
        address indexed contributor,
        uint256 amount
    );

    constructor(
        address _mpc,
        address _nft,
        address _fundsManager,
        address _tlm,
        address _factory
    ) {
        owner = msg.sender;
        MPC = _mpc;
        NFT = _nft;
        fundsManager = _fundsManager;
        tlm = _tlm;
        factory = _factory;
    }

    function intitialize() external {
        require(msg.sender == owner, "CROWDFOUNDING: YOU_ARE_NOT_OWNER");
        Request storage newRequest = requests[numOfRequests];

        newRequest.ercToken = MPC;
        newRequest.erc721 = NFT;
        newRequest.manager = owner;
        newRequest.fundsManager_ = fundsManager;
        newRequest.target = 1000 ether;
        newRequest.deadline = type(uint256).max;
        newRequest.minimum = 10000 gwei;
        newRequest.value = 1000000 * 1e18;
        newRequest.raised = 0;
        newRequest.completed = false;
        IERC20(MPC).mint(newRequest.fundsManager_, newRequest.value);
        emit RequestCreated(numOfRequests);
        numOfRequests++;
    }

    function createRequest(
        address _erc20,
        address _erc721,
        address _manager,
        address _fundsManager
    )
        public
        override
        onlyInitialized
        returns (uint256 requestId, bool icoStarted)
    {
        require(msg.sender == tlm, "You can not call this function");
        requestId = numOfRequests;
        Request storage newRequest = requests[requestId];
        newRequest.ercToken = _erc20;
        newRequest.erc721 = _erc721;
        newRequest.manager = _manager;
        newRequest.fundsManager_ = _fundsManager;
        newRequest.target = 1000 ether;
        newRequest.deadline = block.timestamp + 1 weeks;
        newRequest.minimum = 10000 gwei;
        newRequest.value = 1000000 * 1e18;
        newRequest.raised = 0;
        newRequest.completed = false;
        icoStarted = true;
        IERC20(_erc20).mint(newRequest.fundsManager_, newRequest.value);
        emit RequestCreated(numOfRequests);
        numOfRequests++;
    }

    function contribution(uint _numOfRequest) public payable override _lock {
        assembly {
            // calculate address for request
            mstore(0x00, _numOfRequest)
            mstore(0x20, requests.slot)
            // mstore address
            mstore(0x100, keccak256(0x00, 0x40))
            // safe data from struct to memory storage
            mstore(0x120, sload(add(mload(0x100), 4))) // request.target
            mstore(0x140, sload(add(mload(0x100), 8))) // request.raised
            //  require(request.completed == false,"CROWDFOUNDING: PROJECT_ALREADY_INITIALIZED");
            if sload(add(mload(0x100), 9)) {
                mstore(0x180, 0xb16e7e07)
                revert(0x180, 0x04)
            }
            // require(request.deadline > block.timestamp,"CROWDFOUNDING: REQUEST_TIME_FINISHED");
            if iszero(gt(sload(add(mload(0x100), 5)), timestamp())) {
                mstore(0x180, 0xeceba2af)
                revert(0x180, 0x04)
            }
            // require(msg.value >= request.minimum, "CROWDFOUNDING: TOO_LOW_BUDGET");
            if lt(callvalue(), sload(add(mload(0x100), 6))) {
                mstore(0x180, 0x338de76e)
                revert(0x180, 0x04)
            }
            // uint total = msg.value + request.raised;
            mstore(0x160, add(callvalue(), mload(0x140)))
            // require(total <= request.target, "CROWDFOUNDING: TOO_MUCH_FUNDS");
            if gt(mload(0x160), mload(0x120)) {
                mstore(0x180, 0x602bf072)
                revert(0x180, 0x04)
            }
            // request.contributors[msg.sender] += msg.value;
            mstore(0x00, caller())
            mstore(0x20, add(mload(0x100), 10))
            // address in mapping for msg.sender
            mstore(0x00, keccak256(0x00, 0x40))
            switch eq(sload(mload(0x00)), 0)
            case 1 {
                mstore(0x20, sload(add(mload(0x100), 11)))
                mstore(0x20, add(mload(0x20), 1))
                sstore(add(mload(0x100), 11), mload(0x20))
                // mapping(uint=>address)
                mstore(0x40, add(mload(0x100), 12))
                mstore(0x20, keccak256(0x20, 0x40))
                sstore(mload(0x20), caller())
                sstore(mload(0x00), callvalue())
            }
            default {
                sstore(mload(0x00), add(sload(mload(0x00)), callvalue()))
            }
            //request.raised += msg.value;
            sstore(add(mload(0x100), 8), add(mload(0x140), callvalue()))
            //if (total == request.target) call fundsManager
            if eq(mload(0x120), mload(0x160)) {
                mstore(0x00, 1)
                if iszero(
                    call(
                        gas(),
                        sload(add(mload(0x100), 3)),
                        mload(0x120),
                        0x00,
                        0x20,
                        0,
                        0
                    )
                ) {
                    mstore(0x180, 0x1b03da98)
                    revert(0x180, 0x04)
                }
                if eq(sload(mload(0x100)), sload(MPC.slot)) {
                    sstore(initialized.slot, 1)
                }
                sstore(add(mload(0x100), 9), 1)
            }

            // emit Contributed(uint256,address,uint256)
            {
                mstore(0x00, callvalue())
                log3(
                    0x00,
                    0x20,
                    0xb2ed2e021651f85a4754a44651fc09ac5141bc0329ce4dfe8dd712a5d04a8b39,
                    _numOfRequest,
                    caller()
                )
            }
        }
    }

    function requestYourToken(
        uint _numOfRequest
    ) public override _lock returns (uint amount) {
        Request storage request = requests[_numOfRequest];
        require(
            request.completed == true,
            "CROWDFOUNDING: PROJECT_NOT_INITIALIZED"
        );
        uint valueInvested = request.contributors[msg.sender];
        uint share = (valueInvested * 1e18) / request.target;
        amount = (request.value * share) / 1e18;
        request.contributors[msg.sender] = 0;
        IERC20(request.ercToken).mint(msg.sender, amount - 1);
    }

    function refund(uint _numOfRequest) public override _lock {
        Request storage request = requests[_numOfRequest];
        require(
            request.deadline < block.timestamp && request.completed == false,
            "CWORDFOUNDING: NOT_ALIGIABLE_FOR_REFUND"
        );
        uint amount = request.contributors[msg.sender];
        require(amount > 0, "CROWDFOUNDING: YOU_ARE_NOT_CONTRIBUTOR");
        request.contributors[msg.sender] = 0;
        Transfer.safeTransferETH(msg.sender, amount);
    }

    function getRequestInfo(
        uint _numOfRequest
    )
        public
        view
        returns (
            address ercToken,
            address erc721,
            address manager,
            address fundsManager_,
            uint target,
            uint deadline,
            uint minimum,
            uint value,
            uint raised,
            bool completed
        )
    {
        Request storage request = requests[_numOfRequest];
        return (
            request.ercToken,
            request.erc721,
            request.manager,
            request.fundsManager_,
            request.target,
            request.deadline,
            request.minimum,
            request.value,
            request.raised,
            request.completed
        );
    }

    function getContributorValue(
        uint _numOfProject,
        address contributor
    ) external view returns (uint256 value) {
        Request storage request = requests[_numOfProject];
        value = request.contributors[contributor];
        return (value);
    }

    function getAllContributors(
        uint _numOfProject
    )
        external
        view
        returns (address[] memory addresses, uint256[] memory amounts)
    {
        Request storage request = requests[_numOfProject];
        uint256 numContributors = request.numOfContributors;

        addresses = new address[](numContributors);
        amounts = new uint256[](numContributors);

        for (uint256 i = 0; i < numContributors; i++) {
            address contributor = request.addressOfContributor[i];
            addresses[i] = contributor;
            amounts[i] = request.contributors[contributor];
        }

        return (addresses, amounts);
    }
}
