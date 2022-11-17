const hre = require("hardhat");

const whitelist = require('../whitelists/whitelist_cronosverse.json');

async function main() {
  const marketContract = hre.config.networks[hre.network.name].marketContract;

  // We get the contract to deploy
   const Cronoverse = await hre.ethers.getContractFactory("Cronoverse");

  console.log('market: ', marketContract);

  const cronoverse = await Cronoverse.deploy(marketContract, "0x0C67B99315f218F770A27a05d3a35F5CE430B63a"); 
  await cronoverse.deployed();
  console.log("Cronoverse deployed to:", cronoverse.address); 

  let i = 0;
  const whitelistLen = whitelist.length;
  while(i < whitelistLen) {
    console.log(`whitelist i = ${i}`);
    if (i + 50 >= whitelistLen) {
      await cronoverse.addWhiteList(whitelist.slice(i));
    } else {
      await cronoverse.addWhiteList(whitelist.slice(i, i + 50));
    }
    i += 50;
  }

  //  transfer ownership
  //  const tx = await cronoverse.transferOwnership(owner);
  //  await tx.wait();
  //  const newOwner = await cronoverse.owner();
  //  console.log(`owner is now: ${newOwner}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
