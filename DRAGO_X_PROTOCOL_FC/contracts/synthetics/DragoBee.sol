// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BasketSynthetic.sol";

/// @title DragoBee (DGBEE) – Energy Basket (crude/natural gas/renewables, AI-weighted rebalance)
contract DragoBee is BasketSynthetic {
    constructor(
        address collateralToken,
        address crudeFeed,
        address gasFeed,
        address renewableFeed,
        address ethUsdFeed
    )
        BasketSynthetic(
            "Drago Bee",
            "DGBEE",
            collateralToken,
            _toArray(crudeFeed, gasFeed, renewableFeed),
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
        weights[1] = 3500;
        weights[2] = 1500;
    }
}
