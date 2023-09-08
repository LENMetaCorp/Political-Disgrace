// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PoliticanCardCreator.sol";
import "./PoliticanCorruptionPacks.sol";

contract PoliticalCorruptionControl is AccessControl, ReentrancyGuard {
    PoliticanCardCreator private cardCreator;
    PoliticanCorruptionPacks private corruptionPacks;

    bytes32 public constant CARD_CREATOR_ROLE = keccak256("CARD_CREATOR_ROLE");
    bytes32 public constant CORRUPTION_PACKS_ROLE = keccak256("CORRUPTION_PACKS_ROLE");

    // Drop rates for each rarity
    mapping(string => uint256) public defaultDropRates;

    // Series related data
    struct Series {
        string name;
        string uri;
        uint256 maxPacks;
        uint256 mintedPacks;
        uint256 packPrice;
        uint256[] cardIds;
        mapping(string => uint256) dropRates;
    }

    mapping(string => Series) public seriesMapping;
    string[] public seriesList;

    event CardCreatorAddressUpdated(address indexed newAddress);
    event CorruptionPacksAddressUpdated(address indexed newAddress);
    event SeriesCreated(string indexed seriesName);

    constructor(address _cardCreatorAddress, address _corruptionPacksAddress) {
        cardCreator = PoliticanCardCreator(_cardCreatorAddress);
        corruptionPacks = PoliticanCorruptionPacks(_corruptionPacksAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Existing functions
    function getCardCreatorAddress() public view returns (address) {
        return address(cardCreator);
    }

    function updateCardCreatorAddress(address _cardCreatorAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_cardCreatorAddress != address(0), "Cannot update to zero address");
        require(_cardCreatorAddress != address(cardCreator), "Cannot update to the same address");
        cardCreator = PoliticanCardCreator(_cardCreatorAddress);
        emit CardCreatorAddressUpdated(_cardCreatorAddress);
    }

    function getCorruptionPacksAddress() public view returns (address) {
        return address(corruptionPacks);
    }

    function updateCorruptionPacksAddress(address _corruptionPacksAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_corruptionPacksAddress != address(0), "Cannot update to zero address");
        require(_corruptionPacksAddress != address(corruptionPacks), "Cannot update to the same address");
        corruptionPacks = PoliticanCorruptionPacks(_corruptionPacksAddress);
        emit CorruptionPacksAddressUpdated(_corruptionPacksAddress);
    }

    function getDefaultDropRates() public view returns (uint256[] memory) {
        uint256[] memory rates = new uint256[](6);
        rates[0] = defaultDropRates["Common"];
        rates[1] = defaultDropRates["Uncommon"];
        rates[2] = defaultDropRates["Rare"];
        rates[3] = defaultDropRates["Holo Rare"];
        rates[4] = defaultDropRates["Ultra Rare"];
        rates[5] = defaultDropRates["Secret Rare"];
        return rates;
    }

    function updateDefaultDropRates(uint256[] memory newDropRates) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string[] memory rarities = ["Common", "Uncommon", "Rare", "Holo Rare", "Ultra Rare", "Secret Rare"];
        for (uint256 i = 0; i < newDropRates.length; i++) {
            if (newDropRates[i] > 0) {
                defaultDropRates[rarities[i]] = newDropRates[i];
            }
        }
    }

    function createNewSeries(string memory name, string memory uri, uint256 maxPacks, uint256 packPrice, uint256[] memory cardIds, uint256[] memory dropRates) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(name).length > 0, "Series name cannot be empty");
        require(maxPacks > 0, "Max packs must be greater than zero");

        Series storage newSeries = seriesMapping[name];
        newSeries.name = name;
        newSeries.uri = uri;
        newSeries.maxPacks = maxPacks;
        newSeries.packPrice = packPrice;
        newSeries.cardIds = cardIds;

        string[] memory rarities = ["Common", "Uncommon", "Rare", "Holo Rare", "Ultra Rare", "Secret Rare"];
        for (uint256 i = 0; i < dropRates.length; i++) {
            if (dropRates[i] > 0) {
                newSeries.dropRates[rarities[i]] = dropRates[i];
            } else {
                newSeries.dropRates[rarities[i]] = defaultDropRates[rarities[i]];
            }
        }

        seriesList.push(name);
        emit SeriesCreated(name);
    }

    function getAllSeries() public view returns (string[] memory) {
        return seriesList;
    }

    function getSeriesInfo(string memory name) public view returns (Series memory) {
        return seriesMapping[name];
    }
}