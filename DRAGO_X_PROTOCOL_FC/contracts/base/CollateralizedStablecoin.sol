// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAggregatorV3Interface.sol";

/// @notice Experimental collateral-backed token base. Not production-ready.
abstract contract CollateralizedStablecoin is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10_000;
    uint256 public constant PRICE_PRECISION = 1e8;
    uint256 public constant TOKEN_DECIMALS = 1e18;

    IERC20 public immutable collateralToken;
    IAggregatorV3Interface public collateralUsdFeed;
    IAggregatorV3Interface public fxUsdFeed;

    uint256 public minCollateralRatioBps;
    uint256 public maxStaleSeconds = 3600;
    mapping(address => uint256) public collateralDeposited;

    event Minted(address indexed user, uint256 stableAmount, uint256 collateralAmount);
    event Burned(address indexed user, uint256 stableAmount, uint256 collateralAmount);
    event MinCollateralRatioUpdated(uint256 newRatioBps);
    event FeedsUpdated(address collateralFeed, address fxFeed);
    event MaxStaleSecondsUpdated(uint256 seconds_);

    constructor(
        string memory name_,
        string memory symbol_,
        address collateralToken_,
        address collateralUsdFeed_,
        address fxUsdFeed_,
        uint256 minCollateralRatioBps_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        require(collateralToken_ != address(0), "Invalid collateral");
        require(collateralUsdFeed_ != address(0), "Invalid feed");
        require(minCollateralRatioBps_ >= BPS, "Ratio must be >= 100%");
        collateralToken = IERC20(collateralToken_);
        collateralUsdFeed = IAggregatorV3Interface(collateralUsdFeed_);
        if (fxUsdFeed_ != address(0)) fxUsdFeed = IAggregatorV3Interface(fxUsdFeed_);
        minCollateralRatioBps = minCollateralRatioBps_;
    }

    function mint(uint256 collateralAmount, uint256 minStableOut) external nonReentrant {
        require(collateralAmount > 0, "Zero collateral");
        uint256 stableOut = collateralToStable(collateralAmount);
        require(stableOut >= minStableOut, "Slippage");
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateralDeposited[msg.sender] += collateralAmount;
        _mint(msg.sender, stableOut);
        emit Minted(msg.sender, stableOut, collateralAmount);
    }

    function burn(uint256 stableAmount, uint256 minCollateralOut) external nonReentrant {
        require(stableAmount > 0, "Zero burn");
        require(balanceOf(msg.sender) >= stableAmount, "Insufficient balance");
        uint256 collateralOut = stableToCollateral(stableAmount);
        require(collateralOut <= collateralDeposited[msg.sender], "Insufficient collateral");
        require(collateralOut >= minCollateralOut, "Slippage");
        _burn(msg.sender, stableAmount);
        collateralDeposited[msg.sender] -= collateralOut;
        collateralToken.safeTransfer(msg.sender, collateralOut);
        emit Burned(msg.sender, stableAmount, collateralOut);
    }

    function collateralToStable(uint256 collateralAmount) public view returns (uint256) {
        uint8 decimals_ = IERC20MetadataCompat(collateralToken).decimals();
        require(decimals_ <= 18, "Unsupported collateral decimals");
        uint256 usdValue8 = (collateralAmount * getCollateralUsdPrice()) / (10 ** decimals_);
        uint256 pegValue8 = usdToPeg(usdValue8);
        return (pegValue8 * TOKEN_DECIMALS * BPS) / (PRICE_PRECISION * minCollateralRatioBps);
    }

    function stableToCollateral(uint256 stableAmount) public view returns (uint256) {
        uint8 decimals_ = IERC20MetadataCompat(collateralToken).decimals();
        require(decimals_ <= 18, "Unsupported collateral decimals");
        uint256 pegValue8 = (stableAmount * PRICE_PRECISION * minCollateralRatioBps) / (TOKEN_DECIMALS * BPS);
        uint256 usdValue8 = pegToUsd(pegValue8);
        return (usdValue8 * (10 ** decimals_)) / getCollateralUsdPrice();
    }

    function getCollateralUsdPrice() public view returns (uint256) { return _readFeed(collateralUsdFeed); }
    function getFxUsdRate() public view returns (uint256) {
        if (address(fxUsdFeed) == address(0)) return PRICE_PRECISION;
        return _readFeed(fxUsdFeed);
    }
    function usdToPeg(uint256 usdValue8) public view virtual returns (uint256) {
        return (usdValue8 * getFxUsdRate()) / PRICE_PRECISION;
    }
    function pegToUsd(uint256 pegValue8) public view virtual returns (uint256) {
        return (pegValue8 * PRICE_PRECISION) / getFxUsdRate();
    }

    function setMinCollateralRatioBps(uint256 newRatioBps) external onlyOwner {
        require(newRatioBps >= BPS, "Ratio must be >= 100%");
        minCollateralRatioBps = newRatioBps;
        emit MinCollateralRatioUpdated(newRatioBps);
    }
    function setFeeds(address collateralFeed, address fxFeed) external onlyOwner {
        require(collateralFeed != address(0), "Invalid collateral feed");
        collateralUsdFeed = IAggregatorV3Interface(collateralFeed);
        fxUsdFeed = fxFeed == address(0) ? IAggregatorV3Interface(address(0)) : IAggregatorV3Interface(fxFeed);
        emit FeedsUpdated(collateralFeed, fxFeed);
    }
    function setMaxStaleSeconds(uint256 seconds_) external onlyOwner {
        require(seconds_ > 0 && seconds_ <= 1 days, "Invalid stale period");
        maxStaleSeconds = seconds_;
        emit MaxStaleSecondsUpdated(seconds_);
    }
    // Collateral-backed token balances are position-bound in this prototype.
    // Transfers are disabled until collateral ownership is represented by transferable shares.
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            require(from == address(this) || to == address(this), "Transfers disabled: collateral position bound");
        }
        super._update(from, to, value);
    }

    function _readFeed(IAggregatorV3Interface feed) internal view returns (uint256) {
        require(address(feed) != address(0), "Feed not configured");
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
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

interface IERC20MetadataCompat {
    function decimals() external view returns (uint8);
}
