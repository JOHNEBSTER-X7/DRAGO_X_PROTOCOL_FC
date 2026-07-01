// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/YieldStablecoin.sol";

/// @title DGF – USD Yield stablecoin (auto-compounding, 5-8% APY via lending fees)
contract DGF is YieldStablecoin {
    constructor(address collateralToken, address ethUsdFeed)
        YieldStablecoin(
            "DRAGO X USD Yield",
            "DGF",
            collateralToken,
            ethUsdFeed,
            10_000
        )
    {}
}
