// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BasketSynthetic.sol";

/// @title DragoFox (DGFOX) – Precious Metals Basket (Silver/Platinum/Palladium)
contract DragoFox is BasketSynthetic {
    constructor(
        address collateralToken,
        address silverFeed,
        address platinumFeed,
        address palladiumFeed,
        address ethUsdFeed
    )
        BasketSynthetic(
            "Drago Fox",
            "DGFOX",
            collateralToken,
            _toArray(silverFeed, platinumFeed, palladiumFeed),
            _weights(),
            ethUsdFeed,
            20_000
        )
    {}

    function _toArray(
        address a,
        address b,
        address c
    ) private pure returns (address[] memory feeds) {
        feeds = new address[](3);
        feeds[0] = a;
        feeds[1] = b;
        feeds[2] = c;
    }

    function _weights() private pure returns (uint256[] memory weights) {
        weights = new uint256[](3);
        weights[0] = 5000;
        weights[1] = 3000;
        weights[2] = 2000;
    }
}
