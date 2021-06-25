// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');
require('dotenv').config();

const NATIVE_TOKEN_HOLDER_VAULT = '0x55D757cBA6a886dBa7B01B6625edA243619042c6';
const MASTER_CHEF = '0x181A446A6329Cce688bDA15292DC0b216c97783F';
const MARS_ADDRESS = '0x593B8E416aec29C3922A6768c7C14D8fA3553Dd0';
const DEV_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const FEE_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const MARS_PER_BLOCK = '260000000000000000';
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
  // await deployNativeTokenHolderVault();
  await deployMasterchef();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
