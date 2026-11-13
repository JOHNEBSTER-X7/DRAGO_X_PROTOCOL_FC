const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

function requiredAddress(name) {
  const value = process.env[name];
  if (!value || !hre.ethers.isAddress(value) || value === hre.ethers.ZeroAddress) {
    throw new Error(`Missing or invalid ${name}; public deployment aborted.`);
  }
  return value;
}

async function main() {
  const network = hre.network.name;
  const prefix = network.toUpperCase().replace(/[^A-Z0-9]/g, "_");
  const [deployer] = await hre.ethers.getSigners();
  if (!deployer || !deployer.address) throw new Error("No deployer signer configured.");

  const collateral = requiredAddress(`${prefix}_COLLATERAL_TOKEN`);
  const ethUsd = requiredAddress(`${prefix}_ETH_USD_FEED`);
  const usdJpy = requiredAddress(`${prefix}_USD_JPY_FEED`);
  const xauUsd = requiredAddress(`${prefix}_XAU_USD_FEED`);
  const wtiUsd = requiredAddress(`${prefix}_WTI_USD_FEED`);
  const brentUsd = requiredAddress(`${prefix}_BRENT_USD_FEED`);
  const gasUsd = requiredAddress(`${prefix}_GAS_USD_FEED`);
  const renewableUsd = requiredAddress(`${prefix}_RENEWABLES_USD_FEED`);
  const silverUsd = requiredAddress(`${prefix}_SILVER_USD_FEED`);
  const platinumUsd = requiredAddress(`${prefix}_PLATINUM_USD_FEED`);
  const palladiumUsd = requiredAddress(`${prefix}_PALLADIUM_USD_FEED`);
  const volUsd = requiredAddress(`${prefix}_VOLATILITY_USD_FEED`);

  console.log("Deploying DRAGO X contracts", { network, chainId: hre.network.config.chainId, deployer: deployer.address });
  const deployed = {};
  async function deploy(name, args) {
    const Factory = await hre.ethers.getContractFactory(name);
    const contract = await Factory.deploy(...args);
    await contract.waitForDeployment();
    deployed[name] = await contract.getAddress();
    console.log(`${name}: ${deployed[name]}`);
  }

  await deploy("DGX", [collateral, ethUsd]);
  await deploy("DGZ", [collateral, ethUsd, usdJpy]);
  await deploy("DGF", [collateral, ethUsd]);
  await deploy("DGB", [collateral, ethUsd, usdJpy]);
  await deploy("DGS", [collateral, ethUsd, usdJpy]);
  await deploy("DragoFly", [collateral, wtiUsd, brentUsd, ethUsd]);
  await deploy("DragoEagle", [collateral, xauUsd, ethUsd]);
  await deploy("DragoBee", [collateral, wtiUsd, gasUsd, renewableUsd, ethUsd]);
  await deploy("DragoFox", [collateral, silverUsd, platinumUsd, palladiumUsd, ethUsd]);
  await deploy("DragoLight", [collateral, volUsd, ethUsd]);

  const output = {
    network, chainId: hre.network.config.chainId, deployer: deployer.address,
    collateral, contracts: deployed,
    note: "Deployment output is not audit, collateral adequacy or market-readiness evidence."
  };
  const outDir = path.join(__dirname, "..", "deployments");
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, `${network}.json`), JSON.stringify(output, null, 2) + "\n", { mode: 0o600 });
  console.log("Deployment manifest written to deployments/" + network + ".json");
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
