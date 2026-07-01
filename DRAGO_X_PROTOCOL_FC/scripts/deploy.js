const hre = require("hardhat");

const SEPOLIA_FEEDS = {
  ETH_USD: "0x694AA185713410026Aa091769E1EAF4329F0a0F0",
  USD_JPY: "0xBcE206caE7f0ec07b545EddE607A6dE41D0B0B44",
  XAU_USD: "0x214eD9Da11D2fbe465a6f893C85a9785Ba005bbC",
};

async function deployMockFeed(initialPrice) {
  const MockFeed = await hre.ethers.getContractFactory("MockV3Aggregator");
  const feed = await MockFeed.deploy(8, initialPrice);
  await feed.waitForDeployment();
  return feed.getAddress();
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying DRAGO X Protocol with:", deployer.address);
  console.log("Network:", hre.network.name);

  const ethUsd = SEPOLIA_FEEDS.ETH_USD;
  const usdJpy = SEPOLIA_FEEDS.USD_JPY;
  const xauUsd = SEPOLIA_FEEDS.XAU_USD;

  const wtiUsd = await deployMockFeed(75_00000000);
  const brentUsd = await deployMockFeed(78_00000000);
  const gasUsd = await deployMockFeed(3_50000000);
  const renewableUsd = await deployMockFeed(50_00000000);
  const silverUsd = await deployMockFeed(25_00000000);
  const platinumUsd = await deployMockFeed(950_00000000);
  const palladiumUsd = await deployMockFeed(1000_00000000);
  const volUsd = await deployMockFeed(20_00000000);

  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
  const collateral = await MockERC20.deploy("Wrapped ETH", "WETH", 18);
  await collateral.waitForDeployment();
  const collateralAddr = await collateral.getAddress();
  console.log("Collateral (WETH):", collateralAddr);

  const DGX = await hre.ethers.getContractFactory("DGX");
  const dgx = await DGX.deploy(collateralAddr, ethUsd);
  await dgx.waitForDeployment();

  const DGZ = await hre.ethers.getContractFactory("DGZ");
  const dgz = await DGZ.deploy(collateralAddr, ethUsd, usdJpy);
  await dgz.waitForDeployment();

  const DGF = await hre.ethers.getContractFactory("DGF");
  const dgf = await DGF.deploy(collateralAddr, ethUsd);
  await dgf.waitForDeployment();

  const DGB = await hre.ethers.getContractFactory("DGB");
  const dgb = await DGB.deploy(collateralAddr, ethUsd, usdJpy);
  await dgb.waitForDeployment();

  const DGS = await hre.ethers.getContractFactory("DGS");
  const dgs = await DGS.deploy(collateralAddr, ethUsd, usdJpy);
  await dgs.waitForDeployment();

  const DragoFly = await hre.ethers.getContractFactory("DragoFly");
  const fly = await DragoFly.deploy(collateralAddr, wtiUsd, brentUsd, ethUsd);
  await fly.waitForDeployment();

  const DragoEagle = await hre.ethers.getContractFactory("DragoEagle");
  const eagle = await DragoEagle.deploy(collateralAddr, xauUsd, ethUsd);
  await eagle.waitForDeployment();

  const DragoBee = await hre.ethers.getContractFactory("DragoBee");
  const bee = await DragoBee.deploy(collateralAddr, wtiUsd, gasUsd, renewableUsd, ethUsd);
  await bee.waitForDeployment();

  const DragoFox = await hre.ethers.getContractFactory("DragoFox");
  const fox = await DragoFox.deploy(collateralAddr, silverUsd, platinumUsd, palladiumUsd, ethUsd);
  await fox.waitForDeployment();

  const DragoLight = await hre.ethers.getContractFactory("DragoLight");
  const light = await DragoLight.deploy(collateralAddr, volUsd, ethUsd);
  await light.waitForDeployment();

  const addresses = {
    collateral: collateralAddr,
    DGX: await dgx.getAddress(),
    DGZ: await dgz.getAddress(),
    DGF: await dgf.getAddress(),
    DGB: await dgb.getAddress(),
    DGS: await dgs.getAddress(),
    DragoFly: await fly.getAddress(),
    DragoEagle: await eagle.getAddress(),
    DragoBee: await bee.getAddress(),
    DragoFox: await fox.getAddress(),
    DragoLight: await light.getAddress(),
  };

  console.log("\n=== DRAGO X Protocol Deployment ===");
  console.log(JSON.stringify(addresses, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
