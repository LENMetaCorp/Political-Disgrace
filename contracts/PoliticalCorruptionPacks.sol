// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoliticalCorruptionControl.sol";

contract PoliticalCorruptionPacks is ERC1155, Ownable {
    PoliticalCorruptionControl private controlContract;

    // Event for updating the control contract address
    event ControlContractAddressUpdated(address indexed newAddress);

    // Counter for unique pack token IDs
    uint256 private packTokenIdCounter;

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

    function mintPack(string memory _seriesName) public payable {
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        require(seriesInfo.cardIds.length > 0, "Series does not exist");
        require(msg.value == seriesInfo.packPrice, "Incorrect ETH amount");

        _mint(msg.sender, packTokenIdCounter, 1, "");
        packTokenIdCounter++;
    }

    function openPack(string memory _seriesName, uint256 packTokenId) public {
        PoliticalCorruptionControl.Series memory seriesInfo = controlContract.getSeriesInfo(_seriesName);
        require(seriesInfo.cardIds.length > 0, "Series does not exist");
        require(balanceOf(msg.sender, packTokenId) > 0, "You do not own this pack");

        _burn(msg.sender, packTokenId, 1);

        for (uint256 i = 0; i < 3; i++) {
            uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i)));
            uint256 tokenId = seriesInfo.cardIds[random % seriesInfo.cardIds.length];
            // Mint the Politician NFT here (Assuming a function mintPolitician exists in the PoliticianCards contract)
            // PoliticianCards.mintPolitician(tokenId, msg.sender);
        }
    }
}