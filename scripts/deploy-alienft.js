const hre = require("hardhat");
const { sequence } = require("../sequences/alieNFT-sequence");
const whitelist = require("../whitelists/whitelist_alienft.json");

async function main() {
  const { owner } = hre.config.args;
  // We get the contract to deploy
   const ALIENFT = await hre.ethers.getContractFactory("ALIENFT");
   const membership = hre.config.networks[hre.network.name].membership;

  //Real main net artist address --> 0xfB8c9974360c2BC205bb43E9C2AA8737088a8a70 
  //Real main net membership address --> 0x8d9232Ebc4f06B7b8005CCff0ca401675ceb25F5
  //On deploy transfer ownership to here --> 0x454cfAa623A629CC0b4017aEb85d54C42e91479d
  
  const alieNFT = await ALIENFT.deploy(membership, "0xfB8c9974360c2BC205bb43E9C2AA8737088a8a70");

  await alieNFT.deployed();
  console.log("ALIENFT deployed to:", alieNFT.address); 
  

  //testnet 0x10F7D2BbaEEF04e7b61335ba4b680412d0B167D6
  
  // set the sequence
  try {
    console.log("-----Start setting sequence-------");
    
    console.log('sequence 1');
    await alieNFT.setSequnceChunk(0, sequence.slice(0, 500));
    console.log('sequence 2');
    await alieNFT.setSequnceChunk(1, sequence.slice(500, 1000));
    console.log('sequence 3');
    await alieNFT.setSequnceChunk(2, sequence.slice(1000, 1500));
    console.log('sequence 4');
    await alieNFT.setSequnceChunk(3, sequence.slice(1500, 2000));
    console.log('sequence 5');
    await alieNFT.setSequnceChunk(4, sequence.slice(2000));
    
    console.log("-----End setting sequence-------");
  } catch(err) {
    console.log(err)
    return;
  }

  try{
    console.log('adding whitelist')

    let i = 0;
    const whitelistLen = whitelist.length;
    while(i < whitelistLen) {
      if (i + 50 >= whitelistLen) {
        console.log('last')
        await alieNFT.addWhiteList(whitelist.slice(i));
        break;
      } else {
        console.log(`${i+1} whitelist`)
        await alieNFT.addWhiteList(whitelist.slice(i, i + 50));
      }
      i += 50;
    }

    console.log('whitelist added.')
  }catch(err){
    console.log(err)
  }

  //transfer ownership
  const tx = await alieNFT.transferOwnership(owner);
  await tx.wait();
  const newOwner = await alieNFT.owner();
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
