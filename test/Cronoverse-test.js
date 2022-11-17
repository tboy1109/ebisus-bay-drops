const { expect } = require("chai");
const { ethers } = require("hardhat");
const whitelist = require("../whitelists/whitelist_cronosverse.json");

const parseEther = ethers.utils.parseEther;
describe("Test 4 Busines logic of Cronoverse Drop contract", function () {
  let cronoverse;
  let mockMemberships
  let accounts;
  const normalPrice = [parseEther("695"), parseEther("895"), parseEther("1250")];
  const memberPrice = [parseEther("670"), parseEther("870"), parseEther("1225")];
  const whitelistPrice = [parseEther("670"), parseEther("870"), parseEther("1225")];
  let artist;

  before(async () => {
    const MockMemberships = await ethers.getContractFactory("MockMemberships");
    mockMemberships = await MockMemberships.deploy(5, 3);
    await mockMemberships.deployed();
  });

  beforeEach(async function () {
    accounts = await ethers.getSigners();
    artist = accounts[2];

    const Cronoverse = await ethers.getContractFactory("Cronoverse");
    cronoverse = await Cronoverse.deploy(mockMemberships.address, artist.address);
    await cronoverse.deployed();

    // initialize the cost for test
  })

  it("Should return 1208 for maxSupply()", async function () {    
    expect(await cronoverse.maxSupply()).to.be.equal(1208);
  });

  it("Should add whitelists", async function () {     
    let i = 0;
    const whitelistLen = whitelist.length;
    while(i < whitelistLen) {
      if (i + 50 >= whitelistLen) {
        await cronoverse.addWhiteList(whitelist.slice(i));
      } else {
        await cronoverse.addWhiteList(whitelist.slice(i, i + 50));
      }
      i += 50;
    }
    expect(await cronoverse.isWhiteList(whitelist[0])).to.be.equal(true);
    expect(await cronoverse.isWhiteList(whitelist[whitelistLen- 1])).to.be.equal(true);
    
    await cronoverse.removeWhiteList(whitelist[0]);
    expect(await cronoverse.isWhiteList(whitelist[0])).to.be.equal(false);

    await cronoverse.addWhiteListAddress(whitelist[0]);
    expect(await cronoverse.isWhiteList(whitelist[0])).to.be.equal(true);
  });

  describe("Mint Cost", () => {
    it("Whitelist Price should return 670, 870, 1225 for plain tiles", async function () {
      let i = 0;
      const whitelistLen = whitelist.length;
      while(i < whitelistLen) {
        if (i + 50 >= whitelistLen) {
          await cronoverse.addWhiteList(whitelist.slice(i));
        } else {
          await cronoverse.addWhiteList(whitelist.slice(i, i + 50));
        }
        i += 50;
      }
      await expect(await cronoverse.mintCost(whitelist[0], 320)).to.be.equal(parseEther("670"));
      await expect(await cronoverse.mintCost(whitelist[whitelist.length-1], 236)).to.be.equal(parseEther("870"));
      expect(await cronoverse.mintCost(whitelist[0], 541)).to.be.equal(parseEther("1225"));
    });
    it("Member Price should return 670, 870, 1225 for plain tiles", async function () {    
      await expect(await cronoverse.mintCost(accounts[0].address, 320)).to.be.equal(parseEther("670"));
      await expect(await cronoverse.mintCost(accounts[0].address, 236)).to.be.equal(parseEther("870"));
      expect(await cronoverse.mintCost(accounts[0].address, 541)).to.be.equal(parseEther("1225"));
    });
    it("Regular Price should return 695, 895, 1250 for plain tiles for regular price", async function () {    
      expect(await cronoverse.mintCost(accounts[1].address, 320)).to.be.equal(parseEther("695"));
      expect(await cronoverse.mintCost(accounts[1].address, 236)).to.be.equal(parseEther("895"));
      expect(await cronoverse.mintCost(accounts[1].address, 541)).to.be.equal(parseEther("1250"));
    });
  })

  // describe("Tile Type check", () => {
  //   it("")
  // });
  
  it("Should not mint more than 1208 tokens", async function () {
    await cronoverse.setCost([100, 100, 100], true)
    for(let i = 1; i <= 1208; i ++) {
      await cronoverse.mint(i, {
        from: accounts[0].address,
        value: 100
      });
    }
    await expect( cronoverse.mint(1, {
      from: accounts[0].address,
      value: 100
    }))
    .to.be.revertedWith("Sold out")

    const tokenURI = await cronoverse.tokenURI(1208);
    expect(tokenURI).to.be.equal(`https://ipfs.io/ipfs/QmW9SuSjGEWoqPPj1g2zz1BNnkqoCB1cWHsmnSxUUjZNJ3/1208.json`);
  });

  it("Should not accept invalid token Ids", async function () {
    await expect( cronoverse.mint(1209, {
      from: accounts[0].address,
      value: memberPrice[2]
    }))
    .to.be.revertedWith("Token ID Invalid!")
  });
  
  it("Should pay 603 Cro to the artist and 67 Cro to the fee from member", async function () {
    await cronoverse.mint(1, {
      from: accounts[0].address,
      value: memberPrice[0]
    });
       
    await expect(() => cronoverse.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("603"));
    await expect(() => cronoverse.withdraw()).to.changeEtherBalance(accounts[0], parseEther("67"));
  });
  
  it("Should pay 625.5 Cro to the artist and 69.5 Cro to the fee from regular people", async function () {
    await cronoverse.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice[0]
    });
   
    await expect(() => cronoverse.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("625.5"));
    await expect(() => cronoverse.withdraw()).to.changeEtherBalance(accounts[0], parseEther("69.5"));
  });

  it("Should return minted Ids, 5,7,1, 1000", async () => {
    await cronoverse.mint(5, { from: accounts[0].address, value: memberPrice[0]});
    await cronoverse.mint(7, { from: accounts[0].address, value: memberPrice[0]});
    await cronoverse.mint(1, { from: accounts[0].address, value: memberPrice[0]});
    await cronoverse.mint(1000, { from: accounts[0].address, value: memberPrice[0]});

    expect(await cronoverse.getMintedIds()).to.eql([ethers.BigNumber.from(5),ethers.BigNumber.from(7),ethers.BigNumber.from(1),ethers.BigNumber.from(1000)]);
  });

  it("Should not withdraw for not owner", async function () {
    await cronoverse.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice[0]
    });
   
    await expect(cronoverse.connect(accounts[1]).withdraw())
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not return tokenURI when token ID not exist", async function () {
    await cronoverse.mint(1, {
      from: accounts[0].address,
      value: normalPrice[0]
    });
    
    await expect(cronoverse.tokenURI(23)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
  });
 
  it(`Should return tokenURI when token ID 5`, async function () {
    await cronoverse.mint(5, {
      from: accounts[0].address,
      value: normalPrice[0]
    });
    
    const tokenURI = await cronoverse.tokenURI(5);
    expect(tokenURI).to.be.equal(`https://ipfs.io/ipfs/QmW9SuSjGEWoqPPj1g2zz1BNnkqoCB1cWHsmnSxUUjZNJ3/5.json`);
  });
  
  it("Should modify the baseURI", async function () {
    await cronoverse.mint(5, {
      from: accounts[0].address,
      value: normalPrice[0]
    });

    await cronoverse.setBaseURI("ipfs://testURI");

    const tokenURI = await cronoverse.tokenURI(5);
    expect(tokenURI).to.be.equal(`ipfs://testURI/5.json`);
  });
  
  it("Should return all infos", async function () {
    allInfo = await cronoverse.getInfo();
    expect(allInfo.regularCost).to.be.eql([parseEther("695"), parseEther("895"), parseEther("1250")]);
    expect(allInfo.memberCost).to.be.eql([parseEther("670"), parseEther("870"), parseEther("1225")]);
    expect(allInfo.maxSupply).to.be.equal(1208);
    expect(allInfo.maxMintPerTx).to.be.equal(1);
    expect(allInfo.totalSupply).to.be.equal(0);
  });

  it("Should return presale if current time is in presale.", async function () {
    let now = Date.now();
    console.log("current :", now / 1000 - 1800);
    await cronoverse.setSaleTimeStamp(now / 1000 - 1800);
    
    isOnPresale = await cronoverse.isOnPresale();
    console.log("isOnPresale:", isOnPresale);
    isOnPublicSale = await cronoverse.isOnPublicSale();
    console.log("isOnPublicSale:", isOnPublicSale);
  });
}); 

