// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/VolatilitySynthetic.sol";

/// @title DragoLight (DGL) – Volatility Index synthetic (inverse correlation macro hedge)
contract DragoLight is VolatilitySynthetic {
    constructor(address collateralToken, address volUsdFeed, address ethUsdFeed)
        VolatilitySynthetic(
            "Drago Light",
            "DGL",
            collateralToken,
            volUsdFeed,
            ethUsdFeed,
            20_000
        )
    {}
}
