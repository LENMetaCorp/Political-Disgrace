require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contract with the account:", deployer.address);

  const Contract = await hre.ethers.getContractFactory("PoliticalCorruptionPacksERC721Upgradable");

  // Define constructor arguments
  const uri = "ipfs://QmZfLyEWRAMTv6NkLUnUv5bAgnRp9vW8K6ZrLETJDHXQX9/";
  const controlContractAddress = process.env.CONTROL_CONTRACT_ADDRESS;
  const allowedSeaDrop = [process.env.SEADROP_ADDRESS];

  // Deploy the contract
  const contract = await Contract.deploy(uri, controlContractAddress, allowedSeaDrop);

  await contract.deployed();

  console.log("Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
