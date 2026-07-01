# DRAGO X Protocol FC

A complete Hardhat project for the **DRAGO X** DeFi protocol featuring 5 collateral-backed stablecoins and 5 Chainlink-oracle synthetic assets.

## Tokens

### Stablecoins
| Token | Symbol | Description |
|-------|--------|-------------|
| DGX | DGX | USD 1:1 stablecoin (primary settlement) |
| DGZ | DGZ | JPY 1:1 DeFi-native stablecoin |
| DGF | DGF | USD Yield stablecoin (5–8% APY staking) |
| DGB | DGB | JPY Institutional (200%+ overcollateralization) |
| DGS | DGS | USD/JPY Multi-FX basket stablecoin |

### Synthetic Assets
| Token | Symbol | Description |
|-------|--------|-------------|
| Drago Fly | DGFLY | Crude Oil (WTI/Brent via Chainlink) |
| Drago Eagle | DGE | Gold (XAU/USD) |
| Drago Bee | DGBEE | Energy basket (crude/gas/renewables) |
| Drago Fox | DGFOX | Precious metals basket (Ag/Pt/Pd) |
| Drago Light | DGL | Volatility index (inverse correlation hedge) |

## Prerequisites

- [Node.js](https://nodejs.org/) v18+
- npm or yarn
- A wallet with testnet ETH (for Sepolia deployment)

## Installation

```bash
cd DRAGO_X_PROTOCOL_FC
npm install
```

## Configuration

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Required variables for testnet deployment:

```
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
MUMBAI_RPC_URL=https://polygon-mumbai.g.alchemy.com/v2/YOUR_KEY
BNB_TESTNET_RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545
```

## Compile

```bash
npm run compile
```

## Test

```bash
npm test
```

Run with coverage report:

```bash
npm run coverage
```

## Deploy

### Sepolia (all 10 contracts)

```bash
npm run deploy:sepolia
```

### Mumbai

```bash
npm run deploy:mumbai
```

### BNB Testnet

```bash
npm run deploy:bnb
```

## Project Structure

```
DRAGO_X_PROTOCOL_FC/
├── contracts/
│   ├── base/           # Shared base contracts
│   ├── stablecoins/    # DGX, DGZ, DGF, DGB, DGS
│   ├── synthetics/     # DragoFly, Eagle, Bee, Fox, Light
│   ├── interfaces/     # Chainlink interfaces
│   └── mocks/          # Test mocks
├── scripts/deploy.js
├── test/test.js
├── hardhat.config.js
└── package.json
```

## Architecture

- **OpenZeppelin v5**: `ERC20`, `Ownable`, `ReentrancyGuard`
- **Chainlink**: `AggregatorV3Interface` for all oracle pricing
- **Collateral**: Users deposit WETH (or configured ERC20) to mint; burn returns collateral
- **Synthetics**: 200%+ overcollateralization required
- **DGF Staking**: Stake DGF tokens to earn auto-compounding yield (5–8% APY)

## Networks

| Network | Chain ID | Config Key |
|---------|----------|------------|
| Sepolia | 11155111 | `sepolia` |
| Mumbai | 80001 | `mumbai` |
| BNB Testnet | 97 | `bnbTestnet` |

## License

MIT
