// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC2981} from "../../node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Marketplace {
    uint256 public marketplaceFee = 250;
    uint256 public constant MAX_FEE = 1000;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint private unlocked = 1;
    address public owner;

    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public earnings;

    event ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemSold(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        address buyer
    );

    event ListingCancelled(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    event ListingUpdated(
        address indexed nftContract,
        uint256 tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyItemOwner(address nftContract, uint256 tokenId) {
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not an owner"
        );
        _;
    }

    modifier isListed(address nftContract, uint256 tokenId) {
        require(listings[nftContract][tokenId].price > 0, "Item not listed");
        _;
    }
    modifier notListed(address nftContract, uint256 tokenId) {
        require(
            listings[nftContract][tokenId].price == 0,
            "Item already listed"
        );
        _;
    }

    modifier _lock() {
        require(unlocked == 1, "Funds manager: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyItemOwner(nftContract, tokenId)
        notListed(nftContract, tokenId)
    {
        require(price > 0, "Price must be greater than 0");
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this) ||
                IERC721(nftContract).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
            "Marketplace not approved"
        );
        listings[nftContract][tokenId] = Listing(price, msg.sender);

        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function buyToken(
        address nftContract,
        uint256 tokenId
    ) external payable _lock isListed(nftContract, tokenId) {
        Listing memory listing = listings[nftContract][tokenId];
        require(msg.value == listing.price, "Incorrect amount");
        require(msg.sender != listing.seller, "Cannot buy your own item");

        delete listings[nftContract][tokenId];

        uint256 totalFees = 0;
        uint256 sellerProcceds = listing.price;

        // marketplace fee
        uint256 marketFee = (listing.price * marketplaceFee) / FEE_DENOMINATOR;

        totalFees += marketFee;

        //royalty fee(EIP-2981)

        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        if (
            IERC2981(nftContract).supportsInterface(type(IERC2981).interfaceId)
        ) {
            (royaltyRecipient, royaltyAmount) = IERC2981(nftContract)
                .royaltyInfo(tokenId, listing.price);
            if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
                totalFees += royaltyAmount;
                earnings[royaltyRecipient] += royaltyAmount;
            }
        }

        sellerProcceds -= totalFees;
        IERC721(nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );

        earnings[listing.seller] += sellerProcceds;
        earnings[owner] += marketFee;

        emit ItemSold(
            listing.seller,
            nftContract,
            tokenId,
            listing.price,
            msg.sender
        );
    }

    function cancelListing(
        address nftContract,
        uint256 tokenId
    )
        external
        onlyItemOwner(nftContract, tokenId)
        isListed(nftContract, tokenId)
    {
        delete listings[nftContract][tokenId];

        emit ListingCancelled(msg.sender, nftContract, tokenId);
    }

    function updateListing(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        onlyItemOwner(nftContract, tokenId)
        isListed(nftContract, tokenId)
    {
        require(newPrice > 0, "Orice must be above zero");

        uint256 oldPrice = listings[nftContract][tokenId].price;
        listings[nftContract][tokenId].price = newPrice;

        emit ListingUpdated(nftContract, tokenId, oldPrice, newPrice);
    }

    function withdraw() external _lock {
        uint256 amount = earnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        earnings[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "Withdraw failed");
    }

    function setMarketplaceFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_FEE, "Fee too high");
        marketplaceFee = _fee;
    }

    function emergencyWithdraw() external onlyOwner {
        address marketplaceOwner = owner;
        uint256 amount = earnings[marketplaceOwner];

        require(amount > 0, "No fees to withdraw");

        earnings[marketplaceOwner] = 0;

        (bool success, ) = payable(marketplaceOwner).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    // View functions
    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[nftContract][tokenId];
    }

    function isItemListed(
        address nftContract,
        uint256 tokenId
    ) external view returns (bool) {
        return listings[nftContract][tokenId].price > 0;
    }
}
