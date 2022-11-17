const { expect } = require("chai");
const { ethers } = require("hardhat");
const { sequence } = require("../sequences/lolitaFriends-sequence");
const parseEther = ethers.utils.parseEther;

describe("Test 4 Busines logic of LolitaFriends Drop contract", function () {
  let lolitaFriends;
  let mockMemberships
  let accounts;
  const regularPrice = parseEther("245");
  const memberPrice = parseEther("200");
  let artist;

  beforeEach(async function () {
    accounts = await ethers.getSigners();
    artist = accounts[2];
    const MockMemberships = await ethers.getContractFactory("MockMemberships");
    mockMemberships = await MockMemberships.deploy(5, 3);
    await mockMemberships.deployed();

    const LolitaFriends = await ethers.getContractFactory("LolitaFriends");
    lolitaFriends = await LolitaFriends.deploy(mockMemberships.address, artist.address);
    await lolitaFriends.deployed();

    await lolitaFriends.setSequnceChunk(0, sequence.slice(0, 500));
    await lolitaFriends.setSequnceChunk(1, sequence.slice(500, 1000));
    await lolitaFriends.setSequnceChunk(2, sequence.slice(1000, 1500));
    await lolitaFriends.setSequnceChunk(3, sequence.slice(1500, 2000));
    await lolitaFriends.setSequnceChunk(4, sequence.slice(2000));
  })

  it("Should mint 32 tokens for the artist", async function () {     
    const balance = await lolitaFriends.balanceOf(artist.address);
    expect(balance).to.be.equal(32);
    
    let tokenURI = await lolitaFriends.tokenURI(1);
    expect(tokenURI).to.be.equal(`ipfs://QmbgkhdcfUU8KxtEoYnqwLtkUPvpGkXKa9Pma71zQHbVrx/1.json`);

    tokenURI = await lolitaFriends.tokenURI(32);
    expect(tokenURI).to.be.equal(`ipfs://QmbgkhdcfUU8KxtEoYnqwLtkUPvpGkXKa9Pma71zQHbVrx/32.json`);
  });
  
  it("Should return 2468 for the sequence length", async function () {     
    const length = await lolitaFriends.getLen();
    expect(length)
      .to.be.equal(2468);
  });

  it("Should return 2500 for maxSupply()", async function () {    
    expect(await lolitaFriends.maxSupply()).to.be.equal(2500);
  });
    
  it("Should return 35 for totalSupply():artist 32 + new 3 tokens", async function () {
      await lolitaFriends.mint(3, {
            from: accounts[0].address,
            value: parseEther("987")
          });
    expect(await lolitaFriends.totalSupply()).to.be.equal(35);
  });
  
  it("Should return 15 for canMint()", async function () {    
    expect(await lolitaFriends.canMint(accounts[1].address)).to.be.equal(15);
  });
 
  it("Should return 200 for member price", async function () {    
    expect(await lolitaFriends.mintCost(accounts[0].address)).to.be.equal(memberPrice);
  });
  
  it("Should return 245 for regular price", async function () {    
    expect(await lolitaFriends.mintCost(accounts[1].address)).to.be.equal(regularPrice);
  });

  it("Should not mint more than 15 at a time", async function () {
    await expect( lolitaFriends.mint(16, {
        from: accounts[0].address,
        value: parseEther("3200")
      }))
      .to.be.revertedWith("not mint more than max amount");  
  });

  it("Should not mint more than 2500 tokens", async function () {
    await lolitaFriends.setMemberCost(100)
    for(let i = 0; i < 164; i ++) {
      await lolitaFriends.mint(15, {
        from: accounts[0].address,
        value: 100 * 15
      });
    }

    await lolitaFriends.mint(8, {
      from: accounts[0].address,
      value: 100 * 8
    });
    
    await expect( lolitaFriends.mint(1, {
      from: accounts[0].address,
      value: 100 * 1
    }))
    .to.be.revertedWith("sold out!");  

    const tokenURI = await lolitaFriends.tokenURI(sequence[2349]);
    expect(tokenURI).to.be.equal(`ipfs://QmbgkhdcfUU8KxtEoYnqwLtkUPvpGkXKa9Pma71zQHbVrx/${sequence[2349]}.json`);
  });
  
  it("Should pay from member: 180 Cro artist and 20 Cro fee", async function () {
    await lolitaFriends.mint(1, {
      from: accounts[0].address,
      value: memberPrice
    });
       
    await expect(() => lolitaFriends.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("180"));
    await expect(() => lolitaFriends.withdraw()).to.changeEtherBalance(accounts[0], parseEther("20"));
  });

  it("Should pay from regular people: 220.5 Cro artist and 24.5Cro fee", async function () {
    await lolitaFriends.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: regularPrice
    });
   
    await expect(() => lolitaFriends.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("220.5"));
    await expect(() => lolitaFriends.withdraw()).to.changeEtherBalance(accounts[0], parseEther("24.5"));
  });

 
  it("Should pay to the artist for 10 tokens of membership: 1800 Cro", async function () {
    await lolitaFriends.mint(10, {
      from: accounts[0].address,
      value: parseEther("2000")
    });
  
    await expect(() => lolitaFriends.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("1800"));
    await expect(() => lolitaFriends.withdraw()).to.changeEtherBalance(accounts[0], parseEther("200"));
  });

  it("Should pay to the artist for 10 tokens of regular people: 2250 Cro", async function () {
    await lolitaFriends.connect(accounts[1]).mint(10, {
      from: accounts[1].address,
      value: parseEther("2450")
    });
  
    await expect(() => lolitaFriends.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("2205"));
    await expect(() => lolitaFriends.withdraw()).to.changeEtherBalance(accounts[0], parseEther("245"));
  });
  
  it("Should not withdraw for not owner", async function () {
    await lolitaFriends.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: regularPrice
    });
   
    await expect(lolitaFriends.connect(accounts[1]).withdraw())
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not return tokenURI when token ID not exist", async function () {    
    await expect(lolitaFriends.tokenURI(sequence[33])).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
  });
 
  it(`Should return tokenURI when token ID ${sequence[4]}`, async function () {
    await lolitaFriends.mint(5, {
      from: accounts[0].address,
      value: parseEther("3709")
    });
    
    const tokenURI = await lolitaFriends.tokenURI(sequence[4]);
    expect(tokenURI).to.be.equal(`ipfs://QmbgkhdcfUU8KxtEoYnqwLtkUPvpGkXKa9Pma71zQHbVrx/${sequence[4]}.json`);
  });
  
  it("Should modify the baseURI", async function () {
    await lolitaFriends.setBaseURI("ipfs://testURI");

    const tokenURI = await lolitaFriends.tokenURI(32);
    expect(tokenURI).to.be.equal(`ipfs://testURI/32.json`);
  });
  
  it("Should return all infos", async function () {
    allInfo = await lolitaFriends.getInfo();
    expect(allInfo.regularCost).to.be.equal(regularPrice);
    expect(allInfo.memberCost).to.be.equal(memberPrice);
    expect(allInfo.maxSupply).to.be.equal(2500);
    expect(allInfo.maxMintPerTx).to.be.equal(15);
    expect(allInfo.totalSupply).to.be.equal(32);
  });

  it("Should not mint when paused", async function () {
    await lolitaFriends.pause();
    await expect(lolitaFriends.mint(1, {
      from: accounts[0].address,
      value: regularPrice
    })).to.be.revertedWith("Pausable: paused");
  });
}); 

