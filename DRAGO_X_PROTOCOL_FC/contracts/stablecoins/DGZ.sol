// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/CollateralizedStablecoin.sol";

/// @title DGZ – DeFi-native JPY stablecoin (1:1 JPY, oracle-stabilized)
contract DGZ is CollateralizedStablecoin {
    constructor(address collateralToken, address ethUsdFeed, address usdJpyFeed)
        CollateralizedStablecoin(
            "DRAGO X JPY",
            "DGZ",
            collateralToken,
            ethUsdFeed,
            usdJpyFeed,
            10_000
        )
    {}
}
