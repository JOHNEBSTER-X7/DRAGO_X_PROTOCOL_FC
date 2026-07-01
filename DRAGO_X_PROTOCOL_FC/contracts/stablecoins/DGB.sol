// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/CollateralizedStablecoin.sol";

/// @title DGB – JPY Institutional stablecoin (200%+ overcollateralization)
contract DGB is CollateralizedStablecoin {
    constructor(address collateralToken, address ethUsdFeed, address usdJpyFeed)
        CollateralizedStablecoin(
            "DRAGO X JPY Institutional",
            "DGB",
            collateralToken,
            ethUsdFeed,
            usdJpyFeed,
            20_000
        )
    {}
}
