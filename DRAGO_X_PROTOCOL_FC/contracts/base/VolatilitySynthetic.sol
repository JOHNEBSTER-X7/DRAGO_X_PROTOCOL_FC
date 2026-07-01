// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SyntheticAsset.sol";

/// @title VolatilitySynthetic
/// @notice Volatility index synthetic with inverse correlation hedge mechanics
contract VolatilitySynthetic is SyntheticAsset {
    uint256 public inverseFactorBps = 8000;

    event InverseFactorUpdated(uint256 newFactorBps);

    constructor(
        string memory name_,
        string memory symbol_,
        address collateralToken_,
        address volUsdFeed_,
        address collateralUsdFeed_,
        uint256 minCollateralRatioBps_
    )
        SyntheticAsset(
            name_,
            symbol_,
            collateralToken_,
            volUsdFeed_,
            collateralUsdFeed_,
            minCollateralRatioBps_
        )
    {}

    function getAssetUsdPrice() public view override returns (uint256) {
        uint256 volPrice = _readFeed(assetUsdFeed);
        return (PRICE_PRECISION * PRICE_PRECISION * inverseFactorBps) / (volPrice * BPS);
    }

    function setInverseFactorBps(uint256 newFactorBps) external onlyOwner {
        require(newFactorBps > 0 && newFactorBps <= BPS, "Invalid factor");
        inverseFactorBps = newFactorBps;
        emit InverseFactorUpdated(newFactorBps);
    }
}
