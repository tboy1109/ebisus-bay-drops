const hre = require("hardhat");
const {
  sequence
} = require("../sequences/skybox-sequence");
const csvToJson = require('csvtojson');

async function main() {
  const {
    owner
  } = hre.config.args;
  let whitelist = await csvToJson({
      trim:true
  }).fromFile("./whitelists/whitelist_skybox.csv");
  whitelist = whitelist.map(item => item.Address);

  // We get the contract to deploy
  const membership = hre.config.networks[hre.network.name].membership;
  const Skybox = await hre.ethers.getContractFactory("Skybox");
 
  //Real main net artist address --> 0x38D9390cd9034D30E58315193cB1fd38E24137Ef 
  //Real main net membership address --> 0x8d9232Ebc4f06B7b8005CCff0ca401675ceb25F5
  //On deploy transfer ownership to here --> 0x454cfAa623A629CC0b4017aEb85d54C42e91479d
  
  console.log('deploying skybox...');
  const skybox = await Skybox.deploy(membership, "0x38D9390cd9034D30E58315193cB1fd38E24137Ef");

  await skybox.deployed();
  console.log("Skybox deployed to:", skybox.address);
  
  //test address: 0x4CbD2C3e79d2f3e517822F24469eCd59C0DB5974

  // set the sequence
  try {
    console.log("-----Start setting sequence-------");
    console.log('sequence 1');
    await skybox.setSequnceChunk(0, sequence.slice(0, 500));
    console.log('sequence 2');
    await skybox.setSequnceChunk(1, sequence.slice(500, 1000));
    console.log('sequence 3');
    await skybox.setSequnceChunk(2, sequence.slice(1000, 1500));
    console.log('sequence 4');
    await skybox.setSequnceChunk(3, sequence.slice(1500));
    console.log("-----End setting sequence-------");
  } catch(err) {
    console.log(err)
    return;
  }
  
  // mint for artist
  try {
    console.log("first 50 for artist");
    await skybox.mintForArtist(50);
    console.log("Successfully minted for the artist");

    console.log("second 50 for artist");
    await skybox.mintForArtist(50);
    console.log("Successfully minted for the artist");
  } catch (err) {
    console.log(err);
    return;
  }

  try{
    console.log('adding whitelist')

    let i = 0;
    const whitelistLen = whitelist.length;
    while(i < whitelistLen) {
      if (i + 50 >= whitelistLen) {
        console.log('last')
        await skybox.addWhiteList(whitelist.slice(i));
        break;
      } else {
        console.log(`${i+1} whitelist`)
        await skybox.addWhiteList(whitelist.slice(i, i + 50));
      }
      i += 50;
    }

    console.log('whitelist added.')
  }catch(err){
    console.log(err)
  }

  // for the test, set the lock time 15 mins
  // await skybox.setLockPeriod(900);
  await skybox.setStartTime(1646582400);

  //  transfer ownership
  const tx = await skybox.transferOwnership(owner);
  await tx.wait();
  const newOwner = await skybox.owner();
  console.log(`owner is now: ${newOwner}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });