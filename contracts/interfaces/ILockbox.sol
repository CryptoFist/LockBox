// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILockbox {

   struct RewardInfo {
      uint256 rewardAmount;
      uint256 rewardCreateTime;
      uint256 rewardDeadline;
      uint8 rewardID;
   }

   event GiveReward(address recipient, uint256 amount, uint8 id);
   event ClaimReward(address claimer, uint256 amount);

   function give_reward(
      address recipient_, 
      uint256 amount_, 
      uint8 id_
   ) external;
   function claim_rewards() external;
   function setExpirationTime(uint256 expiration_) external;
   function getClaimableRewards() external view returns(uint256);
   function getRewardList() external view returns(RewardInfo[] memory);
   function reclaim_rewards() external;
}