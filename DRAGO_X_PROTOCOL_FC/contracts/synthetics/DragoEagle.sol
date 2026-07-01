// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/SyntheticAsset.sol";

/// @title DragoEagle (DGE) – Gold synthetic (XAU/USD via Chainlink)
contract DragoEagle is SyntheticAsset {
    constructor(address collateralToken, address xauUsdFeed, address ethUsdFeed)
        SyntheticAsset(
            "Drago Eagle",
            "DGE",
            collateralToken,
            xauUsdFeed,
            ethUsdFeed,
            20_000
        )
    {}
}
