// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAggregatorV3Interface.sol";

/// @title SyntheticAsset
/// @notice Base for overcollateralized synthetic assets priced with Chainlink feeds.
/// @dev Prices are normalised to 8 decimals; collateral decimals are read once at deployment.
abstract contract SyntheticAsset is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10_000;
    uint256 public constant PRICE_PRECISION = 1e8;
    uint256 public constant TOKEN_DECIMALS = 1e18;

    IERC20 public immutable collateralToken;
    uint8 public immutable collateralTokenDecimals;
    IAggregatorV3Interface public assetUsdFeed;
    IAggregatorV3Interface public collateralUsdFeed;

    uint256 public minCollateralRatioBps;
    uint256 public maxStaleSeconds = 3600;
    mapping(address => uint256) public collateralDeposited;

    event SyntheticMinted(address indexed user, uint256 assetAmount, uint256 collateralAmount);
    event SyntheticBurned(address indexed user, uint256 assetAmount, uint256 collateralAmount);
    event MinCollateralRatioUpdated(uint256 newRatioBps);
    event FeedsUpdated(address assetFeed, address collateralFeed);

    constructor(
        string memory name_,
        string memory symbol_,
        address collateralToken_,
        address assetUsdFeed_,
        address collateralUsdFeed_,
        uint256 minCollateralRatioBps_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(collateralToken_ != address(0), "Invalid collateral");
        require(assetUsdFeed_ != address(0) && collateralUsdFeed_ != address(0), "Invalid feed");
        require(minCollateralRatioBps_ >= BPS, "Ratio must be >= 100%");
        uint8 decimals_ = IERC20MetadataCompat2(collateralToken_).decimals();
        require(decimals_ <= 18, "Unsupported collateral decimals");

        collateralToken = IERC20(collateralToken_);
        collateralTokenDecimals = decimals_;
        assetUsdFeed = IAggregatorV3Interface(assetUsdFeed_);
        collateralUsdFeed = IAggregatorV3Interface(collateralUsdFeed_);
        minCollateralRatioBps = minCollateralRatioBps_;
    }

    function mint(uint256 collateralAmount, uint256 minAssetOut) external nonReentrant {
        require(collateralAmount > 0, "Zero collateral");
        uint256 assetOut = collateralToAsset(collateralAmount);
        require(assetOut >= minAssetOut, "Slippage");

        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateralDeposited[msg.sender] += collateralAmount;
        _mint(msg.sender, assetOut);
        emit SyntheticMinted(msg.sender, assetOut, collateralAmount);
    }

    function burn(uint256 assetAmount, uint256 minCollateralOut) external nonReentrant {
        require(assetAmount > 0, "Zero burn");
        require(balanceOf(msg.sender) >= assetAmount, "Insufficient balance");

        uint256 collateralOut = assetToCollateral(assetAmount);
        require(collateralOut <= collateralDeposited[msg.sender], "Insufficient collateral");
        require(collateralOut >= minCollateralOut, "Slippage");

        _burn(msg.sender, assetAmount);
        collateralDeposited[msg.sender] -= collateralOut;
        collateralToken.safeTransfer(msg.sender, collateralOut);
        emit SyntheticBurned(msg.sender, assetAmount, collateralOut);
    }

    function collateralToAsset(uint256 collateralAmount) public view returns (uint256) {
        uint256 collateralUsd8 =
            (collateralAmount * getCollateralUsdPrice()) / (10 ** collateralTokenDecimals);
        uint256 maxAssetUsd8 = (collateralUsd8 * BPS) / minCollateralRatioBps;
        return (maxAssetUsd8 * TOKEN_DECIMALS) / getAssetUsdPrice();
    }

    function assetToCollateral(uint256 assetAmount) public view returns (uint256) {
        uint256 assetUsd8 = (assetAmount * getAssetUsdPrice()) / TOKEN_DECIMALS;
        uint256 requiredCollateralUsd8 = (assetUsd8 * minCollateralRatioBps) / BPS;
        return (requiredCollateralUsd8 * (10 ** collateralTokenDecimals)) / getCollateralUsdPrice();
    }

    function getAssetUsdPrice() public view virtual returns (uint256) {
        return _readFeed(assetUsdFeed);
    }

    function getCollateralUsdPrice() public view returns (uint256) {
        return _readFeed(collateralUsdFeed);
    }

    function setMinCollateralRatioBps(uint256 newRatioBps) external onlyOwner {
        require(newRatioBps >= BPS, "Ratio must be >= 100%");
        minCollateralRatioBps = newRatioBps;
        emit MinCollateralRatioUpdated(newRatioBps);
    }

    function setFeeds(address assetFeed, address collateralFeed) external onlyOwner {
        require(assetFeed != address(0) && collateralFeed != address(0), "Invalid feed");
        assetUsdFeed = IAggregatorV3Interface(assetFeed);
        collateralUsdFeed = IAggregatorV3Interface(collateralFeed);
        emit FeedsUpdated(assetFeed, collateralFeed);
    }

    function setMaxStaleSeconds(uint256 seconds_) external onlyOwner {
        require(seconds_ > 0 && seconds_ <= 1 days, "Invalid stale period");
        maxStaleSeconds = seconds_;
    }

    function _readFeed(IAggregatorV3Interface feed) internal view returns (uint256) {
        require(address(feed) != address(0), "Feed not configured");
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        require(answer > 0, "Bad price");
        require(updatedAt != 0 && updatedAt <= block.timestamp, "Invalid timestamp");
        require(answeredInRound >= roundId, "Incomplete round");
        require(block.timestamp - updatedAt <= maxStaleSeconds, "Stale price");
        uint8 feedDecimals = feed.decimals();
        require(feedDecimals <= 18, "Unsupported feed decimals");
        uint256 raw = uint256(answer);
        if (feedDecimals < 8) return raw * (10 ** (8 - feedDecimals));
        if (feedDecimals > 8) return raw / (10 ** (feedDecimals - 8));
        return raw;
    }

}

interface IERC20MetadataCompat2 {
    function decimals() external view returns (uint8);
}
