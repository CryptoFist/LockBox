// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./interfaces/ILockbox.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import 'hardhat/console.sol';

contract Lockbox is Ownable, ILockbox {
   IERC20 private rewardToken;
   uint256 private expiration;
   mapping(address => RewardInfo[]) private rewardInfos; // user => rewardInfos
   uint256 private rewardableAmount;

   constructor (address owner_, address token_, uint256 expiration_) {
      transferOwnership(owner_);
      rewardToken = IERC20(token_);
      expiration = expiration_;
   }

   function give_reward(
      address recipient_, 
      uint256 amount_, 
      uint8 id_
   ) external onlyOwner override {
      require (recipient_ != address(0), 'lockbox: zero address');
      require (amount_ > 0, 'lockbox: reward amount should be greater than zero');

      uint256 curTime = block.timestamp;
      rewardInfos[recipient_].push(RewardInfo({
         rewardAmount: amount_,
         rewardCreateTime: curTime,
         rewardDeadline: curTime + expiration,
         rewardID: id_
      }));
   }

   function claim_rewards() external override {
      require (_msgSender() != address(0), 'lockbox: zero address');
      uint256 curTime = block.timestamp;
      uint256 claimableRewards = _getClaimableRewards(_msgSender(), curTime);
      require(claimableRewards > 0, 'lockbox: no reward');

      _updateRewardStatus(_msgSender(), curTime);
      rewardToken.transfer(_msgSender(), claimableRewards);
   }

   function getClaimableRewards() external view override returns(uint256) {
      require (_msgSender() != address(0), 'lockbox: zero address');
      return _getClaimableRewards(_msgSender(), block.timestamp);
   }

   function getRewardList() external view override returns(RewardInfo[] memory) {
      require (_msgSender() != address(0), 'lockbox: zero address');
      return rewardInfos[_msgSender()];
   }

   function setExpirationTime(uint256 expiration_) external onlyOwner override {
      expiration = expiration_;
   }

   function withDraw() external onlyOwner override {
      rewardToken.transfer(_msgSender(), rewardableAmount);
   }

   function _getClaimableRewards(address user_, uint256 curTime_) internal view returns(uint256) {
      uint256 length = rewardInfos[user_].length;
      uint256 claimableReward = 0;
      if (length == 0) {
         return 0;
      }
      for (uint256 i = 0; i < length; i ++) {
         if (rewardInfos[user_][i].rewardDeadline >= curTime_) {
            claimableReward += rewardInfos[user_][i].rewardAmount;
         }
      }

      return claimableReward;
   }

   function _updateRewardStatus(address user_, uint256 curTime_) internal {
      uint256 length = rewardInfos[user_].length;
      if (length == 0) {
         return;
      }
      for (uint256 i = 0; i < length; i ++) {
         if (rewardInfos[user_][i].rewardDeadline >= curTime_) {
            rewardInfos[user_][i].rewardAmount = 0;
         }
      }
   }
}