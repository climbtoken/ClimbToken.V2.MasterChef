// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');
require('dotenv').config();

const NATIVE_TOKEN_HOLDER_VAULT = '0x6bbF5F13d14f12b5C9876F0C69aaa5574f558819';
const MASTER_CHEF = '0x0272af6574f9b8C4813Dcb3a202bEad2151b0Ac3';
const MARS_ADDRESS = '0xf1a71bcce29b598d812a30baedff860a7dce0aff';
const DEV_ADDRESS = '0xf430b4fe0b47577018df4dea86f89ac7da55eca3';
const FEE_ADDRESS = '0xf430b4fe0b47577018df4dea86f89ac7da55eca3';
const MARS_PER_BLOCK = '300000000000000000';
const START_BLOCK = 8557015;

const deployNativeTokenHolderVault = async () => {
  const NativeTokenHolderVault = await hre.ethers.getContractFactory('NativeTokenHolderVault');
  const nativeTokenHolderVault = await NativeTokenHolderVault.deploy();
  await nativeTokenHolderVault.deployed();

  console.log('[deployNativeTokenHolderVault] nativeTokenHolderVault deployed to: ', nativeTokenHolderVault.address);
};

const deployMasterchef = async () => {
  if (MARS_ADDRESS) {
    const MasterchefContract = await hre.ethers.getContractFactory('Masterchef');
    const masterchefContract = await MasterchefContract.deploy(MARS_ADDRESS, DEV_ADDRESS, FEE_ADDRESS, MARS_PER_BLOCK, START_BLOCK, NATIVE_TOKEN_HOLDER_VAULT);

    await masterchefContract.deployed();
    console.log('[deployMasterchef] masterchefContract deployed to: ', masterchefContract.address);
  }
};

async function main() {
  await deployNativeTokenHolderVault();
  // await deployMasterchef();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
