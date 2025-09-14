// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "../../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "../../node_modules/@openzeppelin/contracts/token/common/ERC2981.sol";

contract ERC721Constructor is ERC721, ERC721URIStorage, ERC2981 {
    using Strings for uint256;
    string private _name;
    string private _symbol;
    uint256 private _nextTokenId;
    uint256 private _maxSupply;
    string private _customBaseURI;
    address public fundsManager;
    address public owner;
    address private royaltyReceiver;
    bool private initialized;

    modifier onlyOnce() {
        require(!initialized, "ERC20: already initialized");
        _;
        initialized = true;
    }

    modifier onlyFundsManager() {
        require(msg.sender == fundsManager, "ERC721: CALLER_IS_NOT_DEPLOYER");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You can`t call this function");
        _;
    }

    constructor() ERC721("", "") {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        address _fundsManager,
        address _owner,
        string memory baseURI
    ) public onlyOnce {
        _name = tokenName;
        _symbol = tokenSymbol;
        fundsManager = _fundsManager;
        owner = _owner;
        _customBaseURI = baseURI;
        _nextTokenId = 1;
    }

    function setMaxSupply(uint256 amount) external onlyOwner {
        _maxSupply = amount;
    }

    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
    }

    function safeMint(address to) public onlyFundsManager returns (uint256) {
        require(_nextTokenId <= _maxSupply, "Exceed max supply at ERC721");
        uint256 tokenId = _nextTokenId++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));
        return tokenId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, tokenId.toString(), ".json")
                : "";
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _customBaseURI;
    }
}
