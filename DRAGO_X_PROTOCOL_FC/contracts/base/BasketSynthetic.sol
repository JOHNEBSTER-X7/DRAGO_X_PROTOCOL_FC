// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SyntheticAsset.sol";
import "../interfaces/IAggregatorV3Interface.sol";

/// @title BasketSynthetic
/// @notice Multi-asset synthetic with weighted oracle basket and rebalancing
abstract contract BasketSynthetic is SyntheticAsset {
    IAggregatorV3Interface[] public componentFeeds;
    uint256[] public componentWeightsBps;

    event BasketRebalanced(uint256[] newWeights);
    event ComponentAdded(address feed, uint256 weightBps);

    constructor(
        string memory name_,
        string memory symbol_,
        address collateralToken_,
        address[] memory feeds_,
        uint256[] memory weightsBps_,
        address collateralUsdFeed_,
        uint256 minCollateralRatioBps_
    )
        SyntheticAsset(
            name_,
            symbol_,
            collateralToken_,
            feeds_[0],
            collateralUsdFeed_,
            minCollateralRatioBps_
        )
    {
        require(feeds_.length == weightsBps_.length, "Length mismatch");
        require(feeds_.length > 0, "Empty basket");

        uint256 totalWeight;
        for (uint256 i = 0; i < feeds_.length; i++) {
            require(feeds_[i] != address(0), "Invalid feed");
            componentFeeds.push(IAggregatorV3Interface(feeds_[i]));
            componentWeightsBps.push(weightsBps_[i]);
            totalWeight += weightsBps_[i];
        }
        require(totalWeight == BPS, "Weights must sum to 100%");
    }

    function getAssetUsdPrice() public view override returns (uint256) {
        uint256 weightedPrice;
        for (uint256 i = 0; i < componentFeeds.length; i++) {
            weightedPrice += _readFeed(componentFeeds[i]) * componentWeightsBps[i];
        }
        return weightedPrice / BPS;
    }

    function rebalanceBasket(uint256[] calldata newWeightsBps) external onlyOwner {
        require(newWeightsBps.length == componentFeeds.length, "Length mismatch");

        uint256 totalWeight;
        for (uint256 i = 0; i < newWeightsBps.length; i++) {
            totalWeight += newWeightsBps[i];
        }
        require(totalWeight == BPS, "Weights must sum to 100%");

        for (uint256 i = 0; i < newWeightsBps.length; i++) {
            componentWeightsBps[i] = newWeightsBps[i];
        }
        emit BasketRebalanced(newWeightsBps);
    }

    function getComponentCount() external view returns (uint256) {
        return componentFeeds.length;
    }
}
