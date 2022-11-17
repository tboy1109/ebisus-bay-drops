const { expect } = require("chai");
const { ethers } = require("hardhat");
const { sequence } = require("../sequences/skybox-sequence");
const csvToJson = require('csvtojson');

const parseEther = ethers.utils.parseEther;
 
describe("Test 4 Busines logic of Skybox Drop contract", function () {
  let skybox;
  let mockMemberships;

  let accounts;
  let owner, other, artist, other1;
  const normalPrice = parseEther("5000");
  const memberPrice = parseEther("4000");
  const whitePrice = parseEther("4000");
  const fee = 10;
  let whitelist;

  before(async function () {
    const MockMemberships = await ethers.getContractFactory("MockMemberships");
    mockMemberships = await MockMemberships.deploy(5, 3);
    await mockMemberships.deployed();

    whitelist = await csvToJson({
        trim:true
    }).fromFile("./whitelists/whitelist_skybox.csv");
    whitelist = whitelist.map(item => item.Address);

  })
  beforeEach(async function () {
    accounts = await ethers.getSigners();
    [owner, other, artist, other1] = accounts;
    const Skybox = await ethers.getContractFactory("Skybox");
    skybox = await Skybox.deploy(mockMemberships.address, artist.address);
    await skybox.deployed();

    await skybox.setSequnceChunk(0, sequence.slice(0, 500));
    await skybox.setSequnceChunk(1, sequence.slice(500, 1000));
    await skybox.setSequnceChunk(2, sequence.slice(1000, 1500));
    await skybox.setSequnceChunk(3, sequence.slice(1500));

    await skybox.mintForArtist(50);
    await skybox.mintForArtist(50); 
  })

  it("Should add whitelists", async function () {     
      let i = 0;

      const whitelistLen = whitelist.length;
      while(i < whitelistLen) {
        if (i + 50 >= whitelistLen) {
          await skybox.addWhiteList(whitelist.slice(i));
        } else {
          await skybox.addWhiteList(whitelist.slice(i, i + 50));
        }
        i += 50;
      }
    expect(await skybox.isWhiteList(whitelist[0])).to.be.equal(true);
    expect(await skybox.isWhiteList(whitelist[whitelistLen- 1])).to.be.equal(true);
    
    await skybox.removeWhiteList(whitelist[0]);
    expect(await skybox.isWhiteList(whitelist[0])).to.be.equal(false);

    await skybox.addWhiteListAddress(whitelist[0]);
    expect(await skybox.isWhiteList(whitelist[0])).to.be.equal(true);
  });
  

  it("Should return 2100 for the sequence length", async function () {     
    const length = await skybox.getLen();
    expect(length)
      .to.be.equal(2100);
  });

  it("Should return 2100 for maxSupply()", async function () {    
    expect(await skybox.maxSupply()).to.be.equal(2100);
  });
    
  it("Should return 3 for canMint()", async function () {    
    expect(await skybox.canMint(other.address)).to.be.equal(0);
    await skybox.addWhiteListAddress(other.address)
    expect(await skybox.canMint(other.address)).to.be.equal(1);
    await skybox.connect(owner).setLockPeriod(0);
    expect(await skybox.canMint(other.address)).to.be.equal(3);
  });
 
  it("Should return 4000 Cro for member price", async function () {    
    expect(await skybox.mintCost(owner.address)).to.be.equal(memberPrice);
  });
  
  it("Should return 5000 Cro for normal price", async function () {    
    expect(await skybox.mintCost(other.address)).to.be.equal(normalPrice);
  });

  it("Should mint 100 tokens for the artist", async function () {    
    const balance = await skybox.balanceOf(artist.address);
    expect(balance).to.be.equal(100);
    
    let tokenURI = await skybox.tokenURI(sequence[0]);
    expect(tokenURI).to.be.equal(`https://www.lazyhorseraceclub.com/skyboxmeta/${sequence[0]}.json`);

    tokenURI = await skybox.tokenURI(sequence[99]);
    expect(tokenURI).to.be.equal(`https://www.lazyhorseraceclub.com/skyboxmeta/${sequence[99]}.json`);
  });

  it("Should not mint more than 3 at a time after WL time", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");
    await skybox.setRegularCost(100);

    await expect( skybox.connect(other).mint(4, {
        value: 300
      }))
      .to.be.revertedWith("not mint more than max amount");  
  });

  it("Should whitelist mint one token while WL time", async function () {
    await skybox.setWhitelistCost(100);
    
    await expect( skybox.mint(1, {value: 100})).to.be.revertedWith("whitelist only can mint this time");
    await skybox.addWhiteListAddress(owner.address);
    await expect( skybox.mint(2, {value: 200})).to.be.revertedWith("only can mint one this time");
    
    await skybox.mint(1, {value: 100});
    expect(await skybox.balanceOf(owner.address)).to.be.equal(1);
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, 90);
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, 10);

    await skybox.setLockPeriod(3600 * 2);
    await ethers.provider.send("evm_increaseTime", [7200]);
    await ethers.provider.send("evm_mine");

    await skybox.setMemberCost(200);
    await skybox.mint(3, {value: 600});
    expect(await skybox.balanceOf(owner.address)).to.be.equal(4);
  });
  
  it("Should pay 400 Cro fee and 3600 Cro to artist from member", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");

    await skybox.mint(1, {
      from: owner.address,
      value: memberPrice
    });
       
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("3600"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("400"));
  });

  it("Should pay whitelist for only 1 token", async function () {
    await skybox.addWhiteListAddress(other.address)
    await skybox.connect(other).mint(1, {
      from: other.address,
      value: whitePrice
    });
       
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("3600"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("400"));

    // already minted 1 token, so should be removed from whitelist
    await expect(skybox.connect(other).mint(1, {
      from: other.address,
      value: normalPrice
    })).to.revertedWith("whitelist only can mint this time");       
  });

  it("Should pay 500 Cro fee and 4500 Cro to artist from regular people", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");

    await skybox.connect(accounts[7]).mint(1, {
      from: accounts[7].address,
      value: normalPrice
    });
   
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("4500"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("500"));
  });

  it("Should pay 800 Cro fee and 7200 Cro to artist with 2 tokens from member", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");

    await accounts[8].sendTransaction({
      to: owner.address,
      value: ethers.utils.parseEther("8000"), // Sends exactly 1.0 ether
    });
    await skybox.mint(2, {
      from: owner.address,
      value: memberPrice.mul(2)
    });
    
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("7200"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("800"));
  });
  
  it("Should pay 1000 Cro fee and 9000 Cro to artist with 2 tokens from regular people", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");

    await accounts[10].sendTransaction({
      to: accounts[5].address,
      value: ethers.utils.parseEther("8000"), // Sends exactly 1.0 ether
    });
    await skybox.connect(accounts[5]).mint(2, {
      from: accounts[5].address,
      value: normalPrice.mul(2)
    });
   
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("9000"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("1000"));
  });
  
  it("Should pay 1000 Cro fee and 9000 Cro to artist with 2 tokens from whitelist", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");
    await accounts[4].sendTransaction({
      to: accounts[9].address,
      value: ethers.utils.parseEther("8000"), // Sends exactly 1.0 ether
    });
    await skybox.addWhiteListAddress(accounts[9].address);

    await skybox.connect(accounts[9]).mint(2, {
      from: accounts[9].address,
      value: normalPrice.mul(2)
    });
   
    await expect(() => skybox.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("9000"));
    await expect(() => skybox.withdraw()).to.changeEtherBalance(owner, parseEther("1000"));
  });

  it("Should not withdraw for not owner", async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");
    await skybox.connect(accounts[11]).mint(1, {
      from: accounts[11].address,
      value: normalPrice
    });
   
    await expect(skybox.connect(other).withdraw())
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not return tokenURI when token ID not exist", async function () {
    await expect(skybox.tokenURI(101)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
  });
 
  it(`Should return tokenURI when token ID ${sequence[10]}`, async function () {
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");
    await skybox.mint(1, {
      from: owner.address,
      value: normalPrice
    });
    
    const tokenURI = await skybox.tokenURI(sequence[10]);
    expect(tokenURI).to.be.equal(`https://www.lazyhorseraceclub.com/skyboxmeta/${sequence[10]}.json`);
  });
  
  it("Should modify the baseURI", async function () {
    await skybox.setMemberCost(100);
    await ethers.provider.send("evm_increaseTime", [3600 * 12]);
    await ethers.provider.send("evm_mine");
    await skybox.mint(1, {
      from: owner.address,
      value: 100
    });
    await skybox.setBaseURI("ipfs://testURI");

    const tokenURI = await skybox.tokenURI(sequence[0]);
    expect(tokenURI).to.be.equal(`ipfs://testURI/${sequence[0]}.json`);
  });
 
  it("Should not mint when paused", async function () {
    await skybox.setMemberCost(100);
    await skybox.pause();
    await expect(skybox.mint(1, {
      from: owner.address,
      value: 100
    })).to.be.revertedWith("Pausable: paused");
  });

  it("Should return all infos", async function () {
    allInfo = await skybox.getInfo();
    expect(allInfo.regularCost).to.be.equal(normalPrice);
    expect(allInfo.memberCost).to.be.equal(memberPrice);
    expect(allInfo.whitelistCost).to.be.equal(whitePrice);
    expect(allInfo.maxSupply).to.be.equal(2100);
    expect(allInfo.maxMintPerTx).to.be.equal(3);
    expect(allInfo.totalSupply).to.be.equal(100);
  });
}); 

