// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CollateralizedStablecoin.sol";

/// @title BasketStablecoin
/// @notice Multi-FX basket stablecoin with weighted USD/JPY reserve oracles
contract BasketStablecoin is CollateralizedStablecoin {
    uint256 public usdWeightBps = 6000;
    uint256 public jpyWeightBps = 4000;

    event BasketWeightsUpdated(uint256 usdWeightBps, uint256 jpyWeightBps);

    constructor(
        string memory name_,
        string memory symbol_,
        address collateralToken_,
        address collateralUsdFeed_,
        address usdJpyFeed_,
        uint256 minCollateralRatioBps_
    )
        CollateralizedStablecoin(
            name_,
            symbol_,
            collateralToken_,
            collateralUsdFeed_,
            usdJpyFeed_,
            minCollateralRatioBps_
        )
    {}

    function getBasketFxRate() public view returns (uint256) {
        uint256 jpyRate = getFxUsdRate();
        return (PRICE_PRECISION * usdWeightBps + jpyRate * jpyWeightBps) / BPS;
    }

    function usdToPeg(uint256 usdValue8) public view override returns (uint256) {
        return (usdValue8 * getBasketFxRate()) / PRICE_PRECISION;
    }

    function pegToUsd(uint256 pegValue8) public view override returns (uint256) {
        return (pegValue8 * PRICE_PRECISION) / getBasketFxRate();
    }

    function setBasketWeights(uint256 usdWeightBps_, uint256 jpyWeightBps_) external onlyOwner {
        require(usdWeightBps_ + jpyWeightBps_ == BPS, "Weights must sum to 100%");
        usdWeightBps = usdWeightBps_;
        jpyWeightBps = jpyWeightBps_;
        emit BasketWeightsUpdated(usdWeightBps_, jpyWeightBps_);
    }
}
