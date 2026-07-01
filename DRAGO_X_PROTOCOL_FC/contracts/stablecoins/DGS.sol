// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BasketStablecoin.sol";

/// @title DGS – USD/JPY Multi-FX Basket stablecoin (weighted reserve)
contract DGS is BasketStablecoin {
    constructor(address collateralToken, address ethUsdFeed, address usdJpyFeed)
        BasketStablecoin(
            "DRAGO X FX Basket",
            "DGS",
            collateralToken,
            ethUsdFeed,
            usdJpyFeed,
            10_000
        )
    {}
}
