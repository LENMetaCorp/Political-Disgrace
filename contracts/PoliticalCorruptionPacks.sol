// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoliticalCorruptionPacks is ERC1155, Ownable {
    struct Series {
        string setName;
        uint256[] politicianTokenIds;
        mapping(uint256 => uint256) dropRates;
        uint256 mintingCost;
    }

    mapping(string => uint256) public defaultDropRates;

    // Mapping from series name to Series struct
    mapping(string => Series) public series;

    // Counter for unique pack token IDs
    uint256 private packTokenIdCounter;

    constructor(string memory uri) ERC1155(uri) {}

    function setDefaultDropRate(string memory rarity, uint256 rate) public onlyOwner {
        defaultDropRates[rarity] = rate;
    }

    function createSeries(string memory _seriesName, string memory _setName, uint256[] memory _politicianTokenIds, uint256 _mintingCost) public onlyOwner {
        Series storage newSeries = series[_seriesName];
        newSeries.setName = _setName;
        newSeries.politicianTokenIds = _politicianTokenIds;
        newSeries.mintingCost = _mintingCost;
    }

    function updateDropRate(string memory _seriesName, uint256 _tokenId, uint256 _dropRate) public onlyOwner {
        require(series[_seriesName].politicianTokenIds.length > 0, "Series does not exist");
        series[_seriesName].dropRates[_tokenId] = _dropRate;
    }

    function mintPack(string memory _seriesName) public payable {
        require(series[_seriesName].politicianTokenIds.length > 0, "Series does not exist");
        require(msg.value == series[_seriesName].mintingCost, "Incorrect ETH amount");

        _mint(msg.sender, packTokenIdCounter, 1, "");
        packTokenIdCounter++;
    }

    function openPack(string memory _seriesName, uint256 packTokenId) public {
        require(series[_seriesName].politicianTokenIds.length > 0, "Series does not exist");
        require(balanceOf(msg.sender, packTokenId) > 0, "You do not own this pack");

        _burn(msg.sender, packTokenId, 1);

        for (uint256 i = 0; i < 3; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i)));
            uint256 tokenId = series[_seriesName].politicianTokenIds[random % series[_seriesName].politicianTokenIds.length];
            // Mint the Politician NFT here (Assuming a function mintPolitician exists in the PoliticianCards contract)
            // PoliticianCards.mintPolitician(tokenId, msg.sender);
        }
    }
}