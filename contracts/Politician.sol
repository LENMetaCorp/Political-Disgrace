// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoliticianCards is ERC1155, Ownable {
    struct Politician {
        string set;
        string name;
        uint256 ageAtBooking;
        string DOB;
        uint256 weightAtBooking;
        uint256 height;
        string addressAtTimeOfBooking;
        string highestHeldPoliticalStation;
        string bookingLocation;
        uint256 bailOrBond;
        string[] charges;
        uint256 copies;
        uint256 rarity;
    }

    // Mapping from set name to politicians
    mapping(string => Politician[]) public politiciansBySet;

    // Mapping from token ID to politician
    mapping(uint256 => Politician) public politicians;

    // Counter for unique token IDs
    uint256 private tokenIdCounter;

    constructor(string memory uri) ERC1155(uri) {}

    function createSet(string memory _setName) public onlyOwner {
        // Creating an empty set
        politiciansBySet[_setName];
    }

    function createPolitician(
        string memory _set,
        string memory _name,
        uint256 _ageAtBooking,
        string memory _DOB,
        uint256 _weightAtBooking,
        uint256 _height,
        string memory _addressAtTimeOfBooking,
        string memory _highestHeldPoliticalStation,
        string memory _bookingLocation,
        uint256 _bailOrBond,
        string[] memory _charges,
        uint256 _copies,
        uint256 _rarity
    ) public onlyOwner {
        require(politiciansBySet[_set].length > 0, "Set does not exist");

        Politician memory newPolitician = Politician({
            set: _set,
            name: _name,
            ageAtBooking: _ageAtBooking,
            DOB: _DOB,
            weightAtBooking: _weightAtBooking,
            height: _height,
            addressAtTimeOfBooking: _addressAtTimeOfBooking,
            highestHeldPoliticalStation: _highestHeldPoliticalStation,
            bookingLocation: _bookingLocation,
            bailOrBond: _bailOrBond,
            charges: _charges,
            copies: _copies,
            rarity: _rarity
        });

        uint256 tokenId = tokenIdCounter;
        politicians[tokenId] = newPolitician;
        politiciansBySet[_set].push(newPolitician);

        tokenIdCounter++;
    }

    function mintPolitician(uint256 tokenId, address to) public onlyOwner {
        require(tokenId < tokenIdCounter, "Token ID does not exist");
        Politician memory politician = politicians[tokenId];
        _mint(to, tokenId, politician.copies * politician.rarity, "");
    }
}