const hre = require("hardhat");
const { sequence } = require("../sequences/croofthrones-sequence");
const whitelist = require("../whitelists/whitelist_croofthrones.json");

async function main() {
  const { owner } = hre.config.args;
  // We get the contract to deploy
   const CROOFTHRONES = await hre.ethers.getContractFactory("Croofthrones");
   const membership = hre.config.networks[hre.network.name].membership;

  //Real main net artist address --> 0x42c0B5Ef07F2b738A4ad32B029bDc37aCd07eF40 
  //Real main net membership address --> 0x8d9232Ebc4f06B7b8005CCff0ca401675ceb25F5
  //On deploy transfer ownership to here --> 0x454cfAa623A629CC0b4017aEb85d54C42e91479d

  const croofThrones = await CROOFTHRONES.attach('0xfA2D9254668d0197bBb2BFe6f21c6D25DF5C770c');
  await croofThrones.setWhitelistCost('10000000000000000');
  await croofThrones.setMemberCost('20000000000000000');
  await croofThrones.setRegularCost('50000000000000000');
  
  // const croofThrones = await CROOFTHRONES.deploy(membership, "0x42c0B5Ef07F2b738A4ad32B029bDc37aCd07eF40", sequence.slice(0, 25));

  // await croofThrones.deployed();
  // console.log("CROOFTHRONES deployed to:", croofThrones.address);
  

  // //testnet 0x10F7D2BbaEEF04e7b61335ba4b680412d0B167D6
  
  // // set the sequence
  // try {
  //   console.log("-----Start setting sequence-------");
    
  //   console.log('sequence 1');
  //   await croofThrones.setSequnceChunk(0, sequence.slice(25, 500));
  //   console.log('sequence 2');
  //   await croofThrones.setSequnceChunk(1, sequence.slice(500, 1000));
  //   console.log('sequence 3');
  //   await croofThrones.setSequnceChunk(2, sequence.slice(1000, 1500));
  //   console.log('sequence 4');
  //   await croofThrones.setSequnceChunk(3, sequence.slice(1500, 2000));
  //   console.log('sequence 5');
  //   await croofThrones.setSequnceChunk(4, sequence.slice(2000));
    
  //   console.log("-----End setting sequence-------");
  // } catch(err) {
  //   console.log(err)
  //   return;
  // }

  // try{
  //   console.log('adding whitelist')

  //   let i = 0;
  //   const whitelistLen = whitelist.length;
  //   while(i < whitelistLen) {
  //     if (i + 50 >= whitelistLen) {
  //       console.log('last')
  //       await croofThrones.addWhiteList(whitelist.slice(i));
  //       break;
  //     } else {
  //       console.log(`${i+1} whitelist`)
  //       await croofThrones.addWhiteList(whitelist.slice(i, i + 50));
  //     }
  //     i += 50;
  //   }

  //   console.log('whitelist added.')
  // }catch(err){
  //   console.log(err)
  // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
