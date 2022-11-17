const { expect } = require("chai");
const { ethers } = require("hardhat");
const { sequence } = require("../sequences/croofthrones-sequence");
const whitelist = require("../whitelists/whitelist_croofthrones.json");

const parseEther = ethers.utils.parseEther;

describe("Test 4 Busines logic of CROOFTHRONES Drop contract", function () {
  let croofThrones;
  let mockMemberships;
  let accounts;
  const normalPrice = parseEther("220");
  const memberPrice = parseEther("180");
  const whitePrice = parseEther("160");
  let artist;

  before(async function () {
    accounts = await ethers.getSigners();
    artist = accounts[2];

    const MockMemberships = await ethers.getContractFactory("MockMemberships");
    mockMemberships = await MockMemberships.deploy(5, 3);
    await mockMemberships.deployed();
  })
  beforeEach(async function () {
    const CROOFTHRONES = await ethers.getContractFactory("Croofthrones");
    croofThrones = await CROOFTHRONES.deploy(mockMemberships.address, artist.address, sequence);
    await croofThrones.deployed();
  })
  it("Should add whitelists", async function () {
    let i = 0;
    const whitelistLen = whitelist.length;
    while (i < whitelistLen) {
      if (i + 50 >= whitelistLen) {
        await croofThrones.addWhiteList(whitelist.slice(i));
      } else {
        await croofThrones.addWhiteList(whitelist.slice(i, i + 50));
      }
      i += 50;
    }
    expect(await croofThrones.isWhiteList(whitelist[0])).to.be.equal(true);
    expect(await croofThrones.isWhiteList(whitelist[whitelistLen - 1])).to.be.equal(true);

    await croofThrones.removeWhiteList(whitelist[0]);
    expect(await croofThrones.isWhiteList(whitelist[0])).to.be.equal(false);

    await croofThrones.addWhiteListAddress(whitelist[0]);
    expect(await croofThrones.isWhiteList(whitelist[0])).to.be.equal(true);
  });


  it("Should return 2500 for the sequence length", async function () {
    const length = await croofThrones.getLen();
    expect(length)
      .to.be.equal(2500);
  });

  it("Should return 2500 for maxSupply()", async function () {
    expect(await croofThrones.maxSupply()).to.be.equal(2500);
  });

  it("Should return 7 for canMint()", async function () {
    expect(await croofThrones.canMint(accounts[1].address)).to.be.equal(7);
  });

  it("Is not whitelist", async function () {
    expect(await croofThrones.isWhiteList(accounts[0].address)).to.be.equal(false);
  });

  it("Is member", async function () {
    // expect(await croofThrones.isMember(accounts[0].address)).to.be.equal(true);
    await expect(croofThrones.isMember(accounts[0].address)).to.be.reverted()
  });

  it("Should return 180 Cro for member price", async function () {
    expect(await croofThrones.mintCost(accounts[0].address)).to.be.equal(memberPrice);
  });

  it("Should return 220 Cro for normal price", async function () {
    expect(await croofThrones.mintCost(accounts[1].address)).to.be.equal(normalPrice);
  });

  it("Should mint 25 tokens for the artist", async function () {
    const balance = await croofThrones.balanceOf(artist.address);
    expect(balance).to.be.equal(25);

    let tokenURI = await croofThrones.tokenURI(2298);
    expect(tokenURI).to.be.equal(`https://ipfs.io/ipfs/QmYMramQceiHTuNWBhDn7ipj1yzvjchJjWPmhEN7oRayK6/2298.json`);

    tokenURI = await croofThrones.tokenURI(1717);
    expect(tokenURI).to.be.equal(`https://ipfs.io/ipfs/QmYMramQceiHTuNWBhDn7ipj1yzvjchJjWPmhEN7oRayK6/1717.json`);
  });

  it("Should not mint more than 7 at a time", async function () {
    await expect(croofThrones.mint(8, {
      from: accounts[0].address,
      value: parseEther("750")
    }))
      .to.be.revertedWith("not mint more than max amount");
  });

  it("Should not mint more than 2500 tokens", async function () {
    await croofThrones.setMemberCost(100);
    for (let i = 0; i < 495; i++) {
      await croofThrones.mint(5, {
        from: accounts[0].address,
        value: 500
      });
    }

    await expect(croofThrones.mint(1, {
      from: accounts[0].address,
      value: 100
    }))
      .to.be.revertedWith("sold out!");
  });

  it("Should pay 27 Cro fee to owner and 153 Cro to artist from member", async function () {
    await croofThrones.mint(1, {
      from: accounts[0].address,
      value: memberPrice
    });

    await expect(() => croofThrones.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("153"));
    await expect(() => croofThrones.withdrawPayments(accounts[0].address)).to.changeEtherBalance(accounts[0], parseEther("27"));
  });

  it("Should pay 24 Cro fee to owner and 136 Cro to artist from whitelist", async function () {
    await croofThrones.addWhiteListAddress(accounts[1].address)
    await croofThrones.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: whitePrice
    });

    await expect(() => croofThrones.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("136"));
    await expect(() => croofThrones.withdrawPayments(accounts[0].address)).to.changeEtherBalance(accounts[0], parseEther("24"));
  });

  it("Should pay 33 Cro fee to owner and 187 Cro to artist from regular people", async function () {
    await croofThrones.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice
    });

    await expect(() => croofThrones.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("187"));
    await expect(() => croofThrones.withdrawPayments(accounts[0].address)).to.changeEtherBalance(accounts[0], parseEther("33"));
  });

  it("Should pay 189 Cro fee to owner and 1071 Cro to artist with 5 tokens from member", async function () {
    await croofThrones.mint(7, {
      from: accounts[0].address,
      value: parseEther("1260")
    });

    await expect(() => croofThrones.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("1071"));
    await expect(() => croofThrones.withdrawPayments(accounts[0].address)).to.changeEtherBalance(accounts[0], parseEther("189"));
  });

  it("Should pay 231 Cro fee to owner and 1309 Cro to artist from regular people", async function () {
    await croofThrones.connect(accounts[1]).mint(7, {
      from: accounts[1].address,
      value: parseEther("1540")
    });

    await expect(() => croofThrones.withdrawPayments(artist.address)).to.changeEtherBalance(artist, parseEther("1309"));
    await expect(() => croofThrones.withdrawPayments(accounts[0].address)).to.changeEtherBalance(accounts[0], parseEther("231"));
  });

  it("Should not withdraw for not owner", async function () {
    await croofThrones.connect(accounts[1]).mint(1, {
      from: accounts[1].address,
      value: normalPrice
    });

    await expect(croofThrones.connect(accounts[1]).withdraw())
      .to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should not return tokenURI when token ID not exist", async function () {
    await expect(croofThrones.tokenURI(36)).to.be.revertedWith("ERC721Metadata: URI query for nonexistent token");
  });

  it("Should return tokenURI when token ID 2298", async function () {
    await croofThrones.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    });

    const tokenURI = await croofThrones.tokenURI(2298);
    expect(tokenURI).to.be.equal("https://ipfs.io/ipfs/QmYMramQceiHTuNWBhDn7ipj1yzvjchJjWPmhEN7oRayK6/2298.json");
  });

  it("Should modify the baseURI", async function () {
    await croofThrones.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    });

    await croofThrones.setBaseURI("ipfs://testURI");

    const tokenURI = await croofThrones.tokenURI(sequence[0]);
    expect(tokenURI).to.be.equal(`ipfs://testURI/${sequence[0]}.json`);
  });

  it("Should not mint when paused", async function () {
    await croofThrones.pause();
    await expect(croofThrones.mint(1, {
      from: accounts[0].address,
      value: normalPrice
    })).to.be.revertedWith("Pausable: paused");
  });

  it("Should return all infos", async function () {
    await croofThrones.mint(7, {
      from: accounts[0].address,
      value: parseEther("1540")
    });
    allInfo = await croofThrones.getInfo();
    expect(allInfo.regularCost).to.be.equal(normalPrice);
    expect(allInfo.memberCost).to.be.equal(memberPrice);
    expect(allInfo.whitelistCost).to.be.equal(whitePrice);
    expect(allInfo.maxSupply).to.be.equal(2500);
    expect(allInfo.maxMintPerTx).to.be.equal(7);
    expect(allInfo.totalSupply).to.be.equal(32);
  });

  it("Should add and remove whitelist", async function () {
    await croofThrones.addWhiteList([accounts[0].address, accounts[1].address]);
    expect(await croofThrones.isWhiteList(accounts[0].address)).to.be.equal(true);
    expect(await croofThrones.isWhiteList(accounts[1].address)).to.be.equal(true);

    await croofThrones.removeWhiteList(accounts[0].address);
    expect(await croofThrones.isWhiteList(accounts[0].address)).to.be.equal(false);
  });
}); 