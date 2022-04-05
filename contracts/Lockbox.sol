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
   address[] private userList;

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
      if (rewardInfos[recipient_].length == 0) {
         userList.push(recipient_);
      }
      rewardInfos[recipient_].push(RewardInfo({
         rewardAmount: amount_,
         rewardCreateTime: curTime,
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
      uint256 curTime = block.timestamp;
      uint256 cnt = 0;
      for (uint256 i = 0; i < rewardInfos[_msgSender()].length; i ++) {
         if (rewardInfos[_msgSender()][i].rewardCreateTime + expiration >= curTime) {
            cnt ++;
         }
      }

      RewardInfo[] memory infos = new RewardInfo[](cnt);
      if (cnt == 0) {
         return infos;
      }

      
      uint256 index = 0;
      for (uint256 i = 0; i < rewardInfos[_msgSender()].length; i ++) {
         if (rewardInfos[_msgSender()][i].rewardCreateTime + expiration >= curTime) {
            cnt ++;
            infos[index++] = rewardInfos[_msgSender()][i];
         }
      }

      return infos;
   }

   function setExpirationTime(uint256 expiration_) external onlyOwner override {
      expiration = expiration_;
   }

   function reclaim_rewards() external onlyOwner override {
      uint256 userCnt = userList.length;
      uint256 curTime_ = block.timestamp;
      uint256 rewardableAmount = 0;
      for (uint256 i = 0; i < userCnt; i ++) {
         address user_ = userList[i];
         uint256 length = rewardInfos[user_].length;

         for (uint256 j = 0; j < length; j ++) {
            if (rewardInfos[user_][i].rewardCreateTime + expiration < curTime_) {
               rewardableAmount += rewardInfos[user_][i].rewardAmount;
               rewardInfos[user_][i].rewardAmount = 0;
            }
         }
      }
      
      rewardToken.transfer(_msgSender(), rewardableAmount);
   }

   function _getClaimableRewards(address user_, uint256 curTime_) internal view returns(uint256) {
      uint256 length = rewardInfos[user_].length;
      uint256 claimableReward = 0;
      if (length == 0) {
         return 0;
      }
      for (uint256 i = 0; i < length; i ++) {
         if (rewardInfos[user_][i].rewardCreateTime + expiration >= curTime_) {
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
         if (rewardInfos[user_][i].rewardCreateTime + expiration >= curTime_) {
            rewardInfos[user_][i].rewardAmount = 0;
         }
      }
   }
}