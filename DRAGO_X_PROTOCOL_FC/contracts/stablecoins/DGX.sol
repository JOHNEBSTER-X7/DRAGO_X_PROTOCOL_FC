// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/CollateralizedStablecoin.sol";

/// @title DGX – DRAGO X USD stablecoin (primary settlement, 1:1 USD)
contract DGX is CollateralizedStablecoin {
    constructor(address collateralToken, address ethUsdFeed)
        CollateralizedStablecoin(
            "DRAGO X USD",
            "DGX",
            collateralToken,
            ethUsdFeed,
            address(0),
            10_000
        )
    {}
}
