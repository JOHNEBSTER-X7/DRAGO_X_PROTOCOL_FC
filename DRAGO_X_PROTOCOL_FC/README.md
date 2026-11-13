# DRAGO X Protocol FC

DRAGO X Protocol is an evolving digital-asset infrastructure project. This repository contains an initial Solidity/Hardhat foundation for five stablecoin concepts and five oracle-priced synthetic-asset concepts.

> **Experimental development only. Not audited or production-ready. Do not deposit real assets or rely on any stated peg, yield, hedge or redemption outcome.**

## Contract portfolio
| Contract | Symbol / intended exposure |
|---|---|
| DGX | USD reference |
| DGZ | JPY reference |
| DGF | USD yield design |
| DGB | JPY institutional design |
| DGS | USD/JPY basket |
| DragoFly | WTI/Brent concept |
| DragoEagle | Gold concept |
| DragoBee | Energy basket |
| DragoFox | Precious-metals basket |
| DragoLight | Volatility-linked concept |

These are design intentions, not evidence of backing, audited pricing, redeemability, liquidity or regulatory approval. DGF's current reward mechanism mints additional tokens algorithmically; this is not proof of lending income, funded yield or automatic compounding. Do not market a fixed APY.

## Development
Requires Node.js 20+.

```bash
npm ci
npm run compile
npm test
npm run coverage
```

## Networks
- Ethereum Sepolia: 11155111
- Polygon Amoy: 80002
- BNB Smart Chain testnet: 97

Polygon Mumbai has been retired; use Amoy for Polygon testnet development.

## Deployment
Copy `.env.example` to `.env`. The deployment script requires explicit, network-specific collateral-token and oracle-feed addresses. It intentionally does not deploy mock collateral or mock feeds to public networks. A valid-looking address does not prove it is the correct feed: verify address, denomination, decimals, freshness and target network.

```bash
npm run deploy:sepolia
npm run deploy:amoy
npm run deploy:bnb
```

The script writes `deployments/<network>.json`. This manifest is not an audit or independent verification report.

## Security release gates
Before any public deployment:
1. Establish a protocol-wide solvency model and correct per-position accounting across token transfers, partial burns, price changes and liquidations.
2. Replace the current algorithmic token-mint reward scheme with a funded, sustainable rewards model; define APY versus compounding precisely.
3. Verify all network-specific oracle feeds; add denomination validation, circuit breakers and governance safeguards.
4. Add adversarial and invariant tests for round sequencing, decimals, stale data, price moves, rounding, fee-on-transfer/rebasing collateral and insolvency.
5. Complete independent audit, formal/invariant testing, deployment verification and legal/regulatory review.
6. Use multisig ownership, role separation, emergency pause and documented incident procedures.

Do not deploy to mainnet or expose users to funds until these gates are completed and signed off.

## Layout
- `contracts/base`: shared token and synthetic-asset contracts
- `contracts/stablecoins`: stablecoin implementations
- `contracts/synthetics`: synthetic-asset implementations
- `contracts/interfaces`: oracle interfaces
- `contracts/mocks`: test-only mocks
- `scripts`: deployment utilities
- `test`: Hardhat tests

## License
MIT
