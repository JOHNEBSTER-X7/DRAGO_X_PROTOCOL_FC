# DRAGO X Protocol FC

DRAGO X Protocol is an evolving digital-asset infrastructure project. This repository currently contains the initial Solidity/Hardhat smart-contract foundation for five stablecoin concepts and five oracle-priced synthetic-asset concepts.

**This repository is not a production-ready financial protocol.** It has not been independently audited, deployment addresses are not evidence of live markets, and the token economics, collateral model, oracle sources, legal classification and operational controls require validation.

## Contract portfolio

### Stablecoin concepts
| Contract | Symbol | Intended reference |
|---|---|---|
| DGX | DGX | USD |
| DGZ | DGZ | JPY |
| DGF | DGF | USD yield design |
| DGB | DGB | JPY institutional design |
| DGS | DGS | USD/JPY basket |

### Synthetic-asset concepts
| Contract | Intended exposure |
|---|---|
| DragoFly | WTI/Brent crude basket |
| DragoEagle | Gold |
| DragoBee | Energy basket |
| DragoFox | Precious-metals basket |
| DragoLight | Volatility-linked concept |

These names describe intended designs, not claims that the assets are backed, redeemable, regulated, or market-ready.

## Repository layout

- `contracts/base`: shared collateralised token and synthetic-asset contracts
- `contracts/stablecoins`: stablecoin implementations
- `contracts/synthetics`: synthetic-asset implementations
- `contracts/interfaces`: oracle interfaces
- `contracts/mocks`: test-only mock tokens and feeds
- `scripts`: deployment utilities
- `test`: Hardhat test suite

## Local development

Requires Node.js 20+.

```bash
npm ci
npm run compile
npm test
npm run coverage
```

## Environment and networks

Copy `.env.example` to `.env` and provide RPC endpoints for the selected test networks. Never commit private keys, mnemonic phrases, RPC credentials or API tokens.

Configured network identifiers:
- Ethereum Sepolia: 11155111
- Polygon Amoy: 80002
- BNB Smart Chain testnet: 97

Deployment scripts must use verified production oracle feeds for the selected network. Mock feeds are for local testing only. Do not deploy the demo script to a public network until its feed configuration, collateral token, constructor arguments and token economics have been reviewed.

## Security and release gates

Before any public testnet or mainnet deployment:
1. Compile with the pinned toolchain and resolve all compiler warnings.
2. Run the full test suite and coverage locally and in CI.
3. Add adversarial tests for oracle decimals, stale/incomplete rounds, collateral accounting, fee-on-transfer/rebasing tokens and rounding.
4. Independently review the economic model and conduct a professional smart-contract audit.
5. Verify each oracle address and feed denomination on the target network.
6. Use multisig ownership, role separation, emergency pause and documented incident procedures.
7. Obtain legal/regulatory review for each jurisdiction and product type.

No deployment or audit claim is made by this README.
