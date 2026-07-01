const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("DRAGO X Protocol", function () {
  async function deployFixture() {
    const [owner, user, other] = await ethers.getSigners();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const collateral = await MockERC20.deploy("WETH", "WETH", 18);

    const MockFeed = await ethers.getContractFactory("MockV3Aggregator");
    const ethUsd = await MockFeed.deploy(8, 2000_00000000);
    const usdJpy = await MockFeed.deploy(8, 150_00000000);
    const xauUsd = await MockFeed.deploy(8, 2000_00000000);
    const wtiUsd = await MockFeed.deploy(8, 75_00000000);
    const brentUsd = await MockFeed.deploy(8, 78_00000000);
    const gasUsd = await MockFeed.deploy(8, 3_50000000);
    const renewableUsd = await MockFeed.deploy(8, 50_00000000);
    const silverUsd = await MockFeed.deploy(8, 25_00000000);
    const platinumUsd = await MockFeed.deploy(8, 950_00000000);
    const palladiumUsd = await MockFeed.deploy(8, 1000_00000000);
    const volUsd = await MockFeed.deploy(8, 20_00000000);

    const collateralAddr = await collateral.getAddress();
    const ethUsdAddr = await ethUsd.getAddress();
    const usdJpyAddr = await usdJpy.getAddress();

    const DGX = await ethers.getContractFactory("DGX");
    const dgx = await DGX.deploy(collateralAddr, ethUsdAddr);

    const DGZ = await ethers.getContractFactory("DGZ");
    const dgz = await DGZ.deploy(collateralAddr, ethUsdAddr, usdJpyAddr);

    const DGF = await ethers.getContractFactory("DGF");
    const dgf = await DGF.deploy(collateralAddr, ethUsdAddr);

    const DGB = await ethers.getContractFactory("DGB");
    const dgb = await DGB.deploy(collateralAddr, ethUsdAddr, usdJpyAddr);

    const DGS = await ethers.getContractFactory("DGS");
    const dgs = await DGS.deploy(collateralAddr, ethUsdAddr, usdJpyAddr);

    const DragoFly = await ethers.getContractFactory("DragoFly");
    const fly = await DragoFly.deploy(
      collateralAddr,
      await wtiUsd.getAddress(),
      await brentUsd.getAddress(),
      ethUsdAddr
    );

    const DragoEagle = await ethers.getContractFactory("DragoEagle");
    const eagle = await DragoEagle.deploy(
      collateralAddr,
      await xauUsd.getAddress(),
      ethUsdAddr
    );

    const DragoBee = await ethers.getContractFactory("DragoBee");
    const bee = await DragoBee.deploy(
      collateralAddr,
      await wtiUsd.getAddress(),
      await gasUsd.getAddress(),
      await renewableUsd.getAddress(),
      ethUsdAddr
    );

    const DragoFox = await ethers.getContractFactory("DragoFox");
    const fox = await DragoFox.deploy(
      collateralAddr,
      await silverUsd.getAddress(),
      await platinumUsd.getAddress(),
      await palladiumUsd.getAddress(),
      ethUsdAddr
    );

    const DragoLight = await ethers.getContractFactory("DragoLight");
    const light = await DragoLight.deploy(
      collateralAddr,
      await volUsd.getAddress(),
      ethUsdAddr
    );

    const deposit = ethers.parseEther("100");
    await collateral.mint(user.address, deposit);
    await collateral.mint(other.address, deposit);

    const contracts = [dgx, dgz, dgf, dgb, dgs, fly, eagle, bee, fox, light];
    for (const c of contracts) {
      await collateral.connect(user).approve(await c.getAddress(), deposit);
      await collateral.connect(other).approve(await c.getAddress(), deposit);
    }

    return {
      owner,
      user,
      other,
      collateral,
      ethUsd,
      usdJpy,
      xauUsd,
      wtiUsd,
      brentUsd,
      gasUsd,
      renewableUsd,
      silverUsd,
      platinumUsd,
      palladiumUsd,
      volUsd,
      dgx,
      dgz,
      dgf,
      dgb,
      dgs,
      fly,
      eagle,
      bee,
      fox,
      light,
    };
  }

  describe("DGX – USD Stablecoin", function () {
    it("mints 1:1 USD stablecoin with collateral", async function () {
      const { user, dgx } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const expected = await dgx.collateralToStable(oneEth);
      await dgx.connect(user).mint(oneEth, expected);
      expect(await dgx.balanceOf(user.address)).to.equal(expected);
      expect(await dgx.collateralDeposited(user.address)).to.equal(oneEth);
    });

    it("burns and returns collateral", async function () {
      const { user, dgx, collateral } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgx.collateralToStable(oneEth);
      await dgx.connect(user).mint(oneEth, minted);
      const before = await collateral.balanceOf(user.address);
      await dgx.connect(user).burn(minted, 0);
      expect(await collateral.balanceOf(user.address)).to.be.gt(before);
      expect(await dgx.balanceOf(user.address)).to.equal(0);
    });

    it("reverts on zero collateral mint", async function () {
      const { user, dgx } = await loadFixture(deployFixture);
      await expect(dgx.connect(user).mint(0, 0)).to.be.revertedWith("Zero collateral");
    });

    it("reverts on slippage", async function () {
      const { user, dgx } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const expected = await dgx.collateralToStable(oneEth);
      await expect(dgx.connect(user).mint(oneEth, expected + 1n)).to.be.revertedWith("Slippage");
    });

    it("reverts on stale oracle", async function () {
      const { user, dgx, ethUsd } = await loadFixture(deployFixture);
      await time.increase(7200);
      await expect(dgx.connect(user).mint(ethers.parseEther("1"), 0)).to.be.revertedWith(
        "Stale price"
      );
      await ethUsd.updateAnswer(2000_00000000);
      await expect(dgx.connect(user).mint(ethers.parseEther("1"), 0)).to.not.be.reverted;
    });

    it("owner can update feeds and ratio", async function () {
      const { owner, other, dgx, ethUsd } = await loadFixture(deployFixture);
      await expect(dgx.connect(other).setMinCollateralRatioBps(11000)).to.be.reverted;
      await dgx.connect(owner).setMinCollateralRatioBps(11000);
      expect(await dgx.minCollateralRatioBps()).to.equal(11000);
      await dgx.connect(owner).setFeeds(await ethUsd.getAddress(), ethers.ZeroAddress);
      await dgx.connect(owner).setMaxStaleSeconds(7200);
      expect(await dgx.maxStaleSeconds()).to.equal(7200);
    });
  });

  describe("DGZ – JPY Stablecoin", function () {
    it("mints JPY-pegged stablecoin using FX oracle", async function () {
      const { user, dgz } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const jpyOut = await dgz.collateralToStable(oneEth);
      await dgz.connect(user).mint(oneEth, jpyOut);
      expect(await dgz.balanceOf(user.address)).to.equal(jpyOut);
      expect(jpyOut).to.be.gt(ethers.parseEther("1500"));
    });

    it("burns JPY stablecoin", async function () {
      const { user, dgz } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgz.collateralToStable(oneEth);
      await dgz.connect(user).mint(oneEth, minted);
      await dgz.connect(user).burn(minted, 0);
      expect(await dgz.balanceOf(user.address)).to.equal(0);
    });

    it("returns correct FX rate", async function () {
      const { dgz } = await loadFixture(deployFixture);
      expect(await dgz.getFxUsdRate()).to.equal(150_00000000);
    });
  });

  describe("DGF – USD Yield Stablecoin", function () {
    it("mints and burns like base stablecoin", async function () {
      const { user, dgf } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgf.collateralToStable(oneEth);
      await dgf.connect(user).mint(oneEth, minted);
      await dgf.connect(user).burn(minted, 0);
      expect(await dgf.balanceOf(user.address)).to.equal(0);
    });

    it("stakes, accrues yield, and claims rewards", async function () {
      const { user, dgf } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgf.collateralToStable(oneEth);
      await dgf.connect(user).mint(oneEth, minted);

      await dgf.connect(user).stake(minted);
      expect(await dgf.stakedBalance(user.address)).to.equal(minted);
      expect(await dgf.totalStaked()).to.equal(minted);

      await time.increase(365 * 24 * 60 * 60);

      const pending = await dgf.pendingRewards(user.address);
      expect(pending).to.be.gt(0);

      await dgf.connect(user).claimRewards();
      expect(await dgf.balanceOf(user.address)).to.be.gt(0);
    });

    it("unstakes tokens", async function () {
      const { user, dgf } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgf.collateralToStable(oneEth);
      await dgf.connect(user).mint(oneEth, minted);
      await dgf.connect(user).stake(minted);
      await dgf.connect(user).unstake(minted / 2n);
      expect(await dgf.stakedBalance(user.address)).to.equal(minted / 2n);
    });

    it("owner sets APY within 5-8% range", async function () {
      const { owner, other, dgf } = await loadFixture(deployFixture);
      await expect(dgf.connect(other).setApyBps(700)).to.be.reverted;
      await dgf.connect(owner).setApyBps(700);
      expect(await dgf.apyBps()).to.equal(700);
      await expect(dgf.connect(owner).setApyBps(900)).to.be.revertedWith("APY out of range");
    });

    it("reverts stake with zero amount", async function () {
      const { user, dgf } = await loadFixture(deployFixture);
      await expect(dgf.connect(user).stake(0)).to.be.revertedWith("Zero stake");
    });
  });

  describe("DGB – JPY Institutional", function () {
    it("requires 200%+ overcollateralization", async function () {
      const { dgb } = await loadFixture(deployFixture);
      expect(await dgb.minCollateralRatioBps()).to.equal(20000);
    });

    it("mints less per collateral than DGZ due to higher ratio", async function () {
      const { dgz, dgb } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const dgzOut = await dgz.collateralToStable(oneEth);
      const dgbOut = await dgb.collateralToStable(oneEth);
      expect(dgbOut).to.equal(dgzOut / 2n);
    });

    it("mints and burns", async function () {
      const { user, dgb } = await loadFixture(deployFixture);
      const twoEth = ethers.parseEther("2");
      const minted = await dgb.collateralToStable(twoEth);
      await dgb.connect(user).mint(twoEth, minted);
      await dgb.connect(user).burn(minted, 0);
      expect(await dgb.balanceOf(user.address)).to.equal(0);
    });
  });

  describe("DGS – Multi-FX Basket", function () {
    it("uses weighted basket FX rate", async function () {
      const { dgs } = await loadFixture(deployFixture);
      const basketRate = await dgs.getBasketFxRate();
      expect(basketRate).to.be.gt(100_000000);
      expect(basketRate).to.be.lt(150_00000000);
    });

    it("mints and burns with basket pricing", async function () {
      const { user, dgs } = await loadFixture(deployFixture);
      const oneEth = ethers.parseEther("1");
      const minted = await dgs.collateralToStable(oneEth);
      await dgs.connect(user).mint(oneEth, minted);
      await dgs.connect(user).burn(minted, 0);
      expect(await dgs.balanceOf(user.address)).to.equal(0);
    });

    it("owner updates basket weights", async function () {
      const { owner, dgs } = await loadFixture(deployFixture);
      await dgs.connect(owner).setBasketWeights(5000, 5000);
      expect(await dgs.usdWeightBps()).to.equal(5000);
      expect(await dgs.jpyWeightBps()).to.equal(5000);
      await expect(dgs.connect(owner).setBasketWeights(6000, 3000)).to.be.revertedWith(
        "Weights must sum to 100%"
      );
    });
  });

  describe("DragoFly – Crude Oil Synthetic", function () {
    it("prices asset as WTI/Brent average", async function () {
      const { fly } = await loadFixture(deployFixture);
      const price = await fly.getAssetUsdPrice();
      expect(price).to.equal(76_50000000);
    });

    it("mints and burns synthetic oil", async function () {
      const { user, fly } = await loadFixture(deployFixture);
      const collateralAmt = ethers.parseEther("10");
      const minted = await fly.collateralToAsset(collateralAmt);
      await fly.connect(user).mint(collateralAmt, minted);
      expect(await fly.balanceOf(user.address)).to.equal(minted);
      await fly.connect(user).burn(minted, 0);
      expect(await fly.balanceOf(user.address)).to.equal(0);
    });

    it("owner updates oil feeds", async function () {
      const { owner, fly, wtiUsd, brentUsd } = await loadFixture(deployFixture);
      await fly.connect(owner).setOilFeeds(
        await wtiUsd.getAddress(),
        await brentUsd.getAddress()
      );
    });
  });

  describe("DragoEagle – Gold Synthetic", function () {
    it("mints and burns gold synthetic", async function () {
      const { user, eagle } = await loadFixture(deployFixture);
      const collateralAmt = ethers.parseEther("5");
      const minted = await eagle.collateralToAsset(collateralAmt);
      await eagle.connect(user).mint(collateralAmt, minted);
      await eagle.connect(user).burn(minted, 0);
      expect(await eagle.balanceOf(user.address)).to.equal(0);
    });

    it("returns gold oracle price", async function () {
      const { eagle } = await loadFixture(deployFixture);
      expect(await eagle.getAssetUsdPrice()).to.equal(2000_00000000);
    });

    it("requires 200%+ collateral", async function () {
      const { eagle } = await loadFixture(deployFixture);
      expect(await eagle.minCollateralRatioBps()).to.equal(20000);
    });
  });

  describe("DragoBee – Energy Basket", function () {
    it("mints and burns energy basket synthetic", async function () {
      const { user, bee } = await loadFixture(deployFixture);
      const collateralAmt = ethers.parseEther("8");
      const minted = await bee.collateralToAsset(collateralAmt);
      await bee.connect(user).mint(collateralAmt, minted);
      await bee.connect(user).burn(minted, 0);
      expect(await bee.balanceOf(user.address)).to.equal(0);
    });

    it("returns weighted basket price", async function () {
      const { bee } = await loadFixture(deployFixture);
      const price = await bee.getAssetUsdPrice();
      expect(price).to.be.gt(0);
    });

    it("owner rebalances basket weights", async function () {
      const { owner, bee } = await loadFixture(deployFixture);
      await bee.connect(owner).rebalanceBasket([4000, 4000, 2000]);
      expect(await bee.getComponentCount()).to.equal(3);
    });
  });

  describe("DragoFox – Precious Metals Basket", function () {
    it("mints and burns metals basket synthetic", async function () {
      const { user, fox } = await loadFixture(deployFixture);
      const collateralAmt = ethers.parseEther("10");
      const minted = await fox.collateralToAsset(collateralAmt);
      await fox.connect(user).mint(collateralAmt, minted);
      await fox.connect(user).burn(minted, 0);
      expect(await fox.balanceOf(user.address)).to.equal(0);
    });

    it("returns weighted metals price", async function () {
      const { fox } = await loadFixture(deployFixture);
      expect(await fox.getAssetUsdPrice()).to.be.gt(0);
    });
  });

  describe("DragoLight – Volatility Index", function () {
    it("returns inverse volatility price", async function () {
      const { light } = await loadFixture(deployFixture);
      const price = await light.getAssetUsdPrice();
      expect(price).to.be.gt(0);
    });

    it("mints and burns volatility synthetic", async function () {
      const { user, light } = await loadFixture(deployFixture);
      const collateralAmt = ethers.parseEther("5");
      const minted = await light.collateralToAsset(collateralAmt);
      await light.connect(user).mint(collateralAmt, minted);
      await light.connect(user).burn(minted, 0);
      expect(await light.balanceOf(user.address)).to.equal(0);
    });

    it("owner updates inverse factor", async function () {
      const { owner, light } = await loadFixture(deployFixture);
      await light.connect(owner).setInverseFactorBps(9000);
      expect(await light.inverseFactorBps()).to.equal(9000);
    });
  });

  describe("Synthetic access control", function () {
    it("only owner can update synthetic feeds", async function () {
      const { owner, other, eagle, ethUsd } = await loadFixture(deployFixture);
      const xauAddr = await eagle.assetUsdFeed();
      await expect(
        eagle.connect(other).setFeeds(xauAddr, await ethUsd.getAddress())
      ).to.be.reverted;
      await eagle.connect(owner).setFeeds(xauAddr, await ethUsd.getAddress());
    });

    it("reverts on zero collateral synthetic mint", async function () {
      const { user, eagle } = await loadFixture(deployFixture);
      await expect(eagle.connect(user).mint(0, 0)).to.be.revertedWith("Zero collateral");
    });

    it("owner can update synthetic ratio and stale seconds", async function () {
      const { owner, eagle } = await loadFixture(deployFixture);
      await eagle.connect(owner).setMinCollateralRatioBps(25000);
      expect(await eagle.minCollateralRatioBps()).to.equal(25000);
      await eagle.connect(owner).setMaxStaleSeconds(7200);
      expect(await eagle.maxStaleSeconds()).to.equal(7200);
    });

    it("reverts burn with insufficient balance", async function () {
      const { user, eagle } = await loadFixture(deployFixture);
      await expect(eagle.connect(user).burn(1, 0)).to.be.revertedWith("Insufficient balance");
    });
  });

  describe("DGF edge cases", function () {
    it("reverts claim with no rewards", async function () {
      const { user, dgf } = await loadFixture(deployFixture);
      await expect(dgf.connect(user).claimRewards()).to.be.revertedWith("No rewards");
    });

    it("reverts burn with zero amount", async function () {
      const { user, dgx } = await loadFixture(deployFixture);
      await expect(dgx.connect(user).burn(0, 0)).to.be.revertedWith("Zero burn");
    });
  });
});
