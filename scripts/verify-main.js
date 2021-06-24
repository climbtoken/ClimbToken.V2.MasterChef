require('dotenv').config();
const hre = require('hardhat');

const MASTER_CHEF = '0xcee60C91a887Da08c6626EF195db0eE736eD716C';
const MARS_ADDRESS = '0x593B8E416aec29C3922A6768c7C14D8fA3553Dd0';
const DEV_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const FEE_ADDRESS = '0x37dAFCcEEA6244e077d08D4C18705a0301DA6102';
const MARS_PER_BLOCK = '260000000000000000';
const START_BLOCK = 8557015;

const masterchefVerify = async () => {
  if (MASTER_CHEF) {
    await hre.run('verify:verify', {
      address: MASTER_CHEF,
      constructorArguments: [
        MARS_ADDRESS,
        DEV_ADDRESS,
        FEE_ADDRESS,
        MARS_PER_BLOCK,
        START_BLOCK
      ]
    })
  }
}

const main = async () => {
  await masterchefVerify();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
