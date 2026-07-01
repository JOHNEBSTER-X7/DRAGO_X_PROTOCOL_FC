// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/SyntheticAsset.sol";
import "../interfaces/IAggregatorV3Interface.sol";

/// @title DragoFly (DGFLY) – Crude Oil synthetic (WTI/Brent via Chainlink)
contract DragoFly is SyntheticAsset {
    IAggregatorV3Interface public wtiUsdFeed;
    IAggregatorV3Interface public brentUsdFeed;

    event OilFeedsUpdated(address wtiFeed, address brentFeed);

    constructor(
        address collateralToken,
        address wtiUsdFeed_,
        address brentUsdFeed_,
        address ethUsdFeed
    )
        SyntheticAsset(
            "Drago Fly",
            "DGFLY",
            collateralToken,
            wtiUsdFeed_,
            ethUsdFeed,
            20_000
        )
    {
        wtiUsdFeed = IAggregatorV3Interface(wtiUsdFeed_);
        brentUsdFeed = IAggregatorV3Interface(brentUsdFeed_);
    }

    function getAssetUsdPrice() public view override returns (uint256) {
        uint256 wti = _readFeed(wtiUsdFeed);
        uint256 brent = _readFeed(brentUsdFeed);
        return (wti + brent) / 2;
    }

    function setOilFeeds(address wtiFeed, address brentFeed) external onlyOwner {
        require(wtiFeed != address(0) && brentFeed != address(0), "Invalid feed");
        wtiUsdFeed = IAggregatorV3Interface(wtiFeed);
        brentUsdFeed = IAggregatorV3Interface(brentFeed);
        emit OilFeedsUpdated(wtiFeed, brentFeed);
    }
}
