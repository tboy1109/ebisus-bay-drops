const { expect } = require("chai");
const { ethers } = require("hardhat");
const { sequence } = require("../sequences/alieNFT-sequence");
const whitelist = require("../whitelists/whitelist_alienft.json");

const parseEther = ethers.utils.parseEther;
 
describe("Test 4 Busines logic of ALIENFT Drop contract", function () {
  let alieNFT;
  let mockMemberships;
  let mockERC20;
  let accounts;
  const normalPrice = parseEther("150");
  const memberPrice = parseEther("125");
  const whitePrice = parseEther("125");
  let artist;

  before(async function () {
    accounts = await ethers.getSigners();
    artist = accounts[2];
    // creat mock ERC20 token contract for impersonating Loot contract
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockERC20 = await MockERC20.connect(accounts[9]).deploy();
    await mockERC20.deployed();

    const MockMemberships = await ethers.getContractFactory("MockMemberships");
    mockMemberships = await MockMemberships.deploy(5, 3);
    await mockMemberships.deployed();
  })
  beforeEach(async function () {
    const ALIENFT = await ethers.getContractFactory("ALIENFT");
    alieNFT = await ALIENFT.deploy(mockMemberships.address, artist.address);
    await alieNFT.deployed();

    await alieNFT.setLootContractAddress(mockERC20.address);

    await alieNFT.setSequnceChunk(0, sequence.slice(0, 500));
    await alieNFT.setSequnceChunk(1, sequence.slice(500, 1000));
    await alieNFT.setSequnceChunk(2, sequence.slice(1000, 1500));
    await alieNFT.setSequnceChunk(3, sequence.slice(1500, 2000));
    await alieNFT.setSequnceChunk(4, sequence.slice(2000));
  })
  it("Should add whitelists", async function () {     
      let i = 0;
      const whitelistLen = whitelist.length;
      while(i < whitelistLen) {
        if (i + 50 >= whitelistLen) {
          await alieNFT.addWhiteList(whitelist.slice(i));
        } else {
          await alieNFT.addWhiteList(whitelist.slice(i, i + 50));
        }
        i += 50;
      }
    expect(await alieNFT.isWhiteList(whitelist[0])).to.be.equal(true);
    expect(await alieNFT.isWhiteList(whitelist[whitelistLen- 1])).to.be.equal(true);
    
    await alieNFT.removeWhiteList(whitelist[0]);
    expect(await alieNFT.isWhiteList(whitelist[0])).to.be.equal(false);

    await alieNFT.addWhiteListAddress(whitelist[0]);
    expect(await alieNFT.isWhiteList(whitelist[0])).to.be.equal(true);
  });
  

  it("Should return 2465 for the sequence length", async function () {     
    const length = await alieNFT.getLen();
    expect(length)
      .to.be.equal(2465);
  });

  it("Should return 2500 for maxSupply()", async function () {    
    expect(await alieNFT.maxSupply()).to.be.equal(2500);
  });
    
  it("Should return 5 for canMint()", async function () {    
    expect(await alieNFT.canMint(accounts[1].address)).to.be.equal(5);
  });
 
  it("Should return 125 Cro for member price", async function () {    
    expect(await alieNFT.mintCost(accounts[0].address)).to.be.equal(memberPrice);
  });
  
  it("Should return 150 Cro for normal price", async function () {    
    expect(await alieNFT.mintCost(accounts[1].address)).to.be.equal(normalPrice);
  });

  it("Should mint 35 tokens for the artist", async function () {     
    const balance = await alieNFT.balanceOf(artist.address);
    expect(balance).to.be.equal(35);
    
    let tokenURI = await alieNFT.tokenURI(1);
    expect(tokenURI).to.be.equal(`ipfs://QmZcWwt2fj3WkpbU7Jf5RtxZpg9M2pzheGC77aZgPmPoUS/1.json`);

    tokenURI = await alieNFT.tokenURI(35);
    expect(tokenURI).to.be.equal(`ipfs://QmZcWwt2fj3WkpbU7Jf5RtxZpg9M2pzheGC77aZgPmPoUS/35.json`);
  });

  it("Should not mint more than 5 at a time", async function () {
    await expect( alieNFT.mint(6, {
        from: accounts[0].address,
        value: parseEther("750")
      }))
      .to.be.revertedWith("not mint more than max amount");  
  });

  it("Should not mint more than 2500 tokens", async function () {
    await alieNFT.setMemberCost(100);
    for(let i = 0; i < 493; i ++) {
      await alieNFT.mint(5, {
        from: accounts[0].address,
        value: 500
      });
    }
    
    await expect( alieNFT.mint(1, {
      from: accounts[0].address,
      value: 100
    }))
    .to.be.revertedWith("sold out!");  
  });
  
  it("Should pay 15 Cro fee and 110 Cro to artist from member", async function () {
    await alieNFT.mint(1, {
      from: accounts[0].address,
      value: memberPrice
    });
       
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("110"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("15"));
  });

  it("Should pay 15 Cro fee and 110 Cro to artist from whitelist", async function () {
    await alieNFT.addWhiteListAddress(accounts[1].address)
    await alieNFT.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: whitePrice
    });
       
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("110"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("15"));
  });

  it("Should pay 15 Cro fee and 110 Cro to artist from 5M loot holder", async function () {
    await alieNFT.connect(accounts[9]).mint(1, {
      from: accounts[9].address,
      value: whitePrice
    });
       
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("110"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("15"));
  });

  it("Should pay 18 Cro fee and 132 Cro to artist from regular people", async function () {
    await alieNFT.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice
    });
   
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("132"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("18"));
  });

  it("Should pay 75 Cro fee and 550 Cro to artist with 5 tokens from member", async function () {
    await alieNFT.mint(5, {
      from: accounts[0].address,
      value: parseEther("625")
    });
    
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("550"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("75"));
  });
  
  it("Should pay 90 Cro fee and 660 Cro to artist from regular people", async function () {
    await alieNFT.connect(accounts[1]).mint(5, {
      from: accounts[1].address,
      value: parseEther("750")
    });
   
    await expect(() => alieNFT.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("660"));
    await expect(() => alieNFT.withdraw()).to.changeEtherBalance(accounts[0], parseEther("90"));
  });

  it("Should not withdraw for not owner", async function () {
    await alieNFT.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice
    });
   
    await expect(alieNFT.connect(accounts[1]).withdraw())
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not return tokenURI when token ID not exist", async function () {
    await expect(alieNFT.tokenURI(36)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
  });
 
  it("Should return tokenURI when token ID 1413", async function () {
    await alieNFT.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    });
    
    const tokenURI = await alieNFT.tokenURI(1413);
    expect(tokenURI).to.be.equal("ipfs://QmZcWwt2fj3WkpbU7Jf5RtxZpg9M2pzheGC77aZgPmPoUS/1413.json");
  });
  
  it("Should modify the baseURI", async function () {
    await alieNFT.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    });

    await alieNFT.setBaseURI("ipfs://testURI");

    const tokenURI = await alieNFT.tokenURI(sequence[0]);
    expect(tokenURI).to.be.equal(`ipfs://testURI/${sequence[0]}.json`);
  });
 
  it("Should not mint when paused", async function () {
    await alieNFT.pause();
    await expect(alieNFT.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    })).to.be.revertedWith("Pausable: paused");
  });

  it("Should return all infos", async function () {
    await alieNFT.mint(5, {
      from: accounts[0].address,
      value: parseEther("750")
    });
    allInfo = await alieNFT.getInfo();
    expect(allInfo.regularCost).to.be.equal(normalPrice);
    expect(allInfo.memberCost).to.be.equal(memberPrice);
    expect(allInfo.whitelistCost).to.be.equal(whitePrice);
    expect(allInfo.maxSupply).to.be.equal(2500);
    expect(allInfo.maxMintPerTx).to.be.equal(5);
    expect(allInfo.totalSupply).to.be.equal(40);
  });

  it("Should add and remove whitelist", async function () {
    await alieNFT.addWhiteList([accounts[0].address, accounts[1].address]);
    expect(await alieNFT.isWhiteList(accounts[0].address)).to.be.equal(true);
    expect(await alieNFT.isWhiteList(accounts[1].address)).to.be.equal(true);

    await alieNFT.removeWhiteList(accounts[0].address);
    expect(await alieNFT.isWhiteList(accounts[0].address)).to.be.equal(false);
  });
}); 

