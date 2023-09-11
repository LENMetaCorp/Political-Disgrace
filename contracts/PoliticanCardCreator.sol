// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoliticalCorruptionControl.sol";

contract PoliticanCardCreator is ERC1155, Ownable {
    PoliticalCorruptionControl private controlContract;

    // Event for updating the control contract address
    event ControlContractAddressUpdated(address indexed newAddress);

    struct Politician {
        string series;
        string name;
        uint256 ageAtBooking;
        string DOB;
        uint256 weightAtBooking;
        uint256 height;
        string highestHeldPoliticalStation;
        string bookingLocation;
        uint256 bailOrBond;
        string[] charges;
        uint256 rarity;
    }

    mapping(string => Politician[]) public politiciansBySeries;
    mapping(uint256 => Politician) public politicians;
    uint256 private tokenIdCounter;

    constructor(string memory uri, address _controlContract) ERC1155(uri) {
        controlContract = PoliticalCorruptionControl(_controlContract);
    }

    // Function to get the ControlContract address
    function getControlContractAddress() public view returns (address) {
        return address(controlContract);
    }

    // Function to update the ControlContract address, can only be called by the default admin role
    function updateControlContractAddress(address _controlContractAddress) public onlyOwner {
        require(_controlContractAddress != address(0), "Cannot update to zero address");
        require(_controlContractAddress != address(controlContract), "Cannot update to the same address");

        controlContract = PoliticalCorruptionControl(_controlContractAddress);
        emit ControlContractAddressUpdated(_controlContractAddress);
    }

    function createPolitician(
        string memory _series,
        string memory _name,
        uint256 _ageAtBooking,
        string memory _DOB,
        uint256 _weightAtBooking,
        uint256 _height,
        string memory _highestHeldPoliticalStation,
        string memory _bookingLocation,
        uint256 _bailOrBond,
        string[] memory _charges,
        uint256 _rarity
    ) public onlyOwner {
        require(bytes(controlContract.seriesMapping[_series].name).length > 0, "Series does not exist");

        Politician memory newPolitician = Politician({
            series: _series,
            name: _name,
            ageAtBooking: _ageAtBooking,
            DOB: _DOB,
            weightAtBooking: _weightAtBooking,
            height: _height,
            highestHeldPoliticalStation: _highestHeldPoliticalStation,
            bookingLocation: _bookingLocation,
            bailOrBond: _bailOrBond,
            charges: _charges,
            rarity: _rarity
        });

        uint256 tokenId = tokenIdCounter;
        politicians[tokenId] = newPolitician;
        politiciansBySeries[_series].push(newPolitician);

        tokenIdCounter++;
    }

    function mintPolitician(uint256 tokenId, address to) public onlyOwner {
        require(tokenId < tokenIdCounter, "Token ID does not exist");
        Politician memory politician = politicians[tokenId];
        _mint(to, tokenId, 1, "");
    }
}