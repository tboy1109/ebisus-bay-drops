const hre = require("hardhat");
const {
  sequence
} = require("../sequences/lolitaFriends-sequence");

async function main() {
  const {
    owner
  } = hre.config.args;
  const membership = hre.config.networks[hre.network.name].membership;
  // We get the contract to deploy
  const LolitaFriends = await hre.ethers.getContractFactory("LolitaFriends");

  //Real main net artist address --> 0x177aB682d6e7c452E68c853DE5b9139fc76E4c4F 
  //Real main net membership address --> 0x8d9232Ebc4f06B7b8005CCff0ca401675ceb25F5
  //On deploy transfer ownership to here --> 0x454cfAa623A629CC0b4017aEb85d54C42e91479d
  
  console.log('deploying lolitaFriends...');
  const lolitaFriends = await LolitaFriends.deploy(membership, "0xAd9602Fb2205473bdC558843B3664232AefA3B95");

  await lolitaFriends.deployed();
  console.log("LolitaFriends deployed to:", lolitaFriends.address);
  
  // set the sequence
  try {
    console.log("-----Start setting sequence-------");
    console.log('sequence 1');
    await lolitaFriends.setSequnceChunk(0, sequence.slice(0, 500));
    console.log('sequence 2');
    await lolitaFriends.setSequnceChunk(1, sequence.slice(500, 1000));
    console.log('sequence 3');
    await lolitaFriends.setSequnceChunk(2, sequence.slice(1000, 1500));
    console.log('sequence 4');
    await lolitaFriends.setSequnceChunk(3, sequence.slice(1500, 2000));
    console.log('sequence 5');
    await lolitaFriends.setSequnceChunk(4, sequence.slice(2000));
    console.log("-----End setting sequence-------");
  } catch(err) {
    console.log(err)
    return;
  }
  
  //  transfer ownership
  // const tx = await lolitaFriends.transferOwnership(owner);
  // await tx.wait();
  // const newOwner = await lolitaFriends.owner();
  // console.log(`owner is now: ${newOwner}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });