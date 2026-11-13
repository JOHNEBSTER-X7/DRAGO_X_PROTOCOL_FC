// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CollateralizedStablecoin.sol";

/// @notice Experimental staking/reward prototype. Rewards are minted and unfunded.
contract YieldStablecoin is CollateralizedStablecoin {
    uint256 public constant MIN_APY_BPS = 500;
    uint256 public constant MAX_APY_BPS = 800;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public apyBps = 650;
    uint256 public totalStaked;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public rewardDebt;
    uint256 public accRewardPerShare;
    uint256 private _lastUpdate = block.timestamp;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ApyUpdated(uint256 newApyBps);

    constructor(string memory name_, string memory symbol_, address collateralToken_, address collateralUsdFeed_, uint256 minCollateralRatioBps_)
        CollateralizedStablecoin(name_, symbol_, collateralToken_, collateralUsdFeed_, address(0), minCollateralRatioBps_)
    {}

    modifier updateRewards(address account) {
        _updatePool();
        _;
        if (account != address(0)) rewardDebt[account] = (stakedBalance[account] * accRewardPerShare) / 1e18;
    }

    function _updatePool() internal {
        if (totalStaked == 0) {
            _lastUpdate = block.timestamp;
            return;
        }
        uint256 elapsed = block.timestamp - _lastUpdate;
        if (elapsed > 0) {
            uint256 reward = (totalStaked * apyBps * elapsed) / (SECONDS_PER_YEAR * BPS);
            accRewardPerShare += (reward * 1e18) / totalStaked;
            _lastUpdate = block.timestamp;
        }
    }

    function stake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Zero stake");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, address(this), amount);
        totalStaked += amount;
        stakedBalance[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
        require(amount > 0, "Zero unstake");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked");
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;
        _transfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        _updatePool();
        uint256 accrued = (stakedBalance[msg.sender] * accRewardPerShare) / 1e18;
        uint256 pending = accrued - rewardDebt[msg.sender];
        require(pending > 0, "No rewards");
        rewardDebt[msg.sender] = accrued;
        // This deliberately mints new supply: rewards are not reserve-funded.
        _mint(msg.sender, pending);
        emit RewardsClaimed(msg.sender, pending);
    }

    function pendingRewards(address account) external view returns (uint256) {
        uint256 acc = accRewardPerShare;
        if (totalStaked > 0) {
            uint256 elapsed = block.timestamp - _lastUpdate;
            uint256 reward = (totalStaked * apyBps * elapsed) / (SECONDS_PER_YEAR * BPS);
            acc += (reward * 1e18) / totalStaked;
        }
        return (stakedBalance[account] * acc) / 1e18 - rewardDebt[account];
    }

    function setApyBps(uint256 newApyBps) external onlyOwner {
        _updatePool();
        require(newApyBps >= MIN_APY_BPS && newApyBps <= MAX_APY_BPS, "APY out of range");
        apyBps = newApyBps;
        emit ApyUpdated(newApyBps);
    }
}
