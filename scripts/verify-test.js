require('dotenv').config();
const hre = require('hardhat');

const NATIVE_TOKEN_HOLDER_VAULT = '0x55D757cBA6a886dBa7B01B6625edA243619042c6';
const MASTER_CHEF = '0x181A446A6329Cce688bDA15292DC0b216c97783F';
const MARS_ADDRESS = '0x593B8E416aec29C3922A6768c7C14D8fA3553Dd0';
const DEV_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const FEE_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const MARS_PER_BLOCK = '260000000000000000';
const START_BLOCK = 8557015;

const verifyNativeTokenHolderVault = async () => {
  if (NATIVE_TOKEN_HOLDER_VAULT) {
    await hre.run('verify:verify', {
      address: NATIVE_TOKEN_HOLDER_VAULT
    })
  }
}

const masterchefVerify = async () => {
  if (MASTER_CHEF) {
    await hre.run('verify:verify', {
      address: MASTER_CHEF,
      constructorArguments: [
        MARS_ADDRESS,
        DEV_ADDRESS,
        FEE_ADDRESS,
        MARS_PER_BLOCK,
        START_BLOCK,
        NATIVE_TOKEN_HOLDER_VAULT
      ]
    })
  }
}

const main = async () => {
  await verifyNativeTokenHolderVault();
  await masterchefVerify();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
