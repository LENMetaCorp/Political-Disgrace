// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PoliticalCorruptionControl.sol";
import "./ERC721SeaDropUpgradeable.sol";

contract PoliticalCorruptionPacksERC721Upgradable is Initializable, ERC721Upgradeable, OwnableUpgradeable, ERC721SeaDropUpgradeable, ReentrancyGuardUpgradeable {
    PoliticalCorruptionControl private controlContract;

    event ControlContractAddressUpdated(address indexed newAddress);
    event MintPackSuccessful(address indexed minter, uint256 quantity);
    event MintSeaDropSuccessful(address indexed minter, uint256 quantity);

    uint256 private packTokenIdCounter;
    string public seaDropSeries;
    uint256 public seaDropMaxSupply;

    mapping(address => uint256) private _tokensMintedByAddress;

    function initialize(string memory uri, address _controlContract, address[] memory allowedSeaDrop) public initializer {
        __ERC721_init(uri, "PoliticalCorruptionPacks");
        __Ownable_init();
        __ERC721SeaDrop_init(uri, "PoliticalCorruptionPacks", allowedSeaDrop);
        __ReentrancyGuard_init();

        controlContract = PoliticalCorruptionControl(_controlContract);
    }

    function getControlContractAddress() public view returns (address) {
        return address(controlContract);
    }

    function updateControlContractAddress(address _controlContractAddress) public onlyOwner {
        require(_controlContractAddress != address(0), "Cannot update to zero address");
        require(_controlContractAddress != address(controlContract), "Cannot update to the same address");

        controlContract = PoliticalCorruptionControl(_controlContractAddress);
        emit ControlContractAddressUpdated(_controlContractAddress);
    }

    function mintPack(address minter, uint256 quantity, string memory _seriesName) public payable nonReentrant {
        require(minter != address(0), "Zero address");
        require(quantity > 0, "Quantity must be greater than zero");

        // Fetch series info once and store it in a local variable
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        require(seriesInfo.cardIds.length > 0, "Series does not exist");

        // Check if max supply has been reached
        require(seriesInfo.mintedPacks + quantity <= seriesInfo.maxPacks, "Max supply reached");

        uint256 totalCost = seriesInfo.packPrice * quantity;
        require(msg.value == totalCost, "Incorrect ETH amount");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(minter, packTokenIdCounter);
            packTokenIdCounter++;
        }

        // Update the _tokensMintedByAddress & mintedPacks in the control contract for SeaDrop series
        _tokensMintedByAddress[minter] += quantity;
        controlContract.updateMintedPacks(_seriesName, seriesInfo.mintedPacks + quantity);

        emit MintPackSuccessful(minter, quantity);
    }

    // Add a function to update this series, restricted to the owner
    function setSeaDropSeries(string memory _newSeries) external onlyOwner {
        seaDropSeries = _newSeries;
        // Fetch and store maxSupply
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_newSeries);
        seaDropMaxSupply = seriesInfo.maxPacks;
    }

    // Implement SeaDrop minting function
    function mintSeaDrop(address minter, uint256 quantity) external override nonReentrant {
        _onlyAllowedSeaDrop(msg.sender);
    
        // Use locally stored maxSupply
        require(packTokenIdCounter + quantity <= seaDropMaxSupply, "Max supply reached for SeaDrop");
    
        // Your existing minting logic here
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(minter, packTokenIdCounter);
            packTokenIdCounter++;
        }
        
        // Update the _tokensMintedByAddress & mintedPacks in the control contract for SeaDrop series
        _tokensMintedByAddress[minter] += quantity;
        controlContract.updateMintedPacks(seaDropSeries, packTokenIdCounter);

        emit MintSeaDropSuccessful(minter, quantity);
    }

    // Implement SeaDrop configuration functions
    function updatePublicDrop(PublicDrop calldata publicDrop) external override onlyOwner {
        _onlyAllowedSeaDrop(msg.sender);
        ISeaDropUpgradeable(msg.sender).updatePublicDrop(publicDrop);
    }

    function updateAllowList(AllowListData calldata allowListData) external override onlyOwner {
        _onlyAllowedSeaDrop(msg.sender);
        ISeaDropUpgradeable(msg.sender).updateAllowList(allowListData);
    }

    // Implement SeaDrop statistics function
    function getMintStats(address minter) external view override returns (uint256 minterNumMinted, uint256 currentTotalSupply, uint256 maxSupply) {
        minterNumMinted = _numberMinted(minter);  // Assuming you have this function
        currentTotalSupply = packTokenIdCounter;
        maxSupply = seaDropMaxSupply;
    }

    function _numberMinted(address minter) internal view returns (uint256) {
        return _tokensMintedByAddress[minter];
    }

    // Implement SeaDrop interface support
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(INonFungibleSeaDropTokenUpgradeable).interfaceId;
    }

    function openPack(string memory _seriesName, uint256 packTokenId) public {
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        require(seriesInfo.cardIds.length > 0, "Series does not exist");
        require(_exists(packTokenId) && ownerOf(packTokenId) == msg.sender, "You do not own this pack");

        _burn(packTokenId);

        for (uint256 i = 0; i < 3; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i)));
            uint256 tokenId = seriesInfo.cardIds[random % seriesInfo.cardIds.length];
            // Mint the Politician NFT here (Assuming a function mintPolitician exists in the PoliticianCards contract)
            // PoliticianCards.mintPolitician(tokenId, msg.sender);
        }
    }
}