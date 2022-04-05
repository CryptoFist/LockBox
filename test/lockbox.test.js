const { expect } = require('chai');
const { ethers } = require('hardhat');

const bigNum = num=>(num + '0'.repeat(18))
const smallNum = num=>(parseInt(num)/bigNum(1))

describe('MarketPlace: Auction', function () {
   before (async function () {
      [
         this.deployer,
         this.owner,
         this.user1,
         this.user2
      ] = await ethers.getSigners();

      this.rewardToken = await ethers.getContractFactory('ERC20Mock');
      this.rewardToken = await this.rewardToken.deploy('Reward', 'REWARD');
      this.rewardToken = await this.rewardToken.deployed();

      console.log('rewardToken address is ', this.rewardToken.address);

      this.lockbox = await ethers.getContractFactory('Lockbox');
      this.lockbox = await this.lockbox.deploy(
         this.owner.address,
         this.rewardToken.address,
         1000 * 10   // expiration time is 10s
      );
      await this.lockbox.deployed();

      console.log('lockbox contract address is ', this.lockbox.address);
   })

   it ('give_reward should be reverted if caller is not owner', async function() {
      await expect(
         this.lockbox.give_reward(this.user1.address, bigNum(1), 0)
      ).revertedWith('Ownable: caller is not the owner');
   })

   it ('give_reward should be reverted with zero amount', async function() {
      await expect(
         this.lockbox.connect(this.owner).give_reward(this.user1.address, bigNum(0), 0)
      ).revertedWith('lockbox: reward amount should be greater than zero');
   }) 

   it ('give_reward and get claimable reward', async function () {
      await this.rewardToken.connect(this.deployer).transfer(this.lockbox.address, bigNum(1));
      await this.lockbox.connect(this.owner).give_reward(this.user1.address, bigNum(1), 0);
      const claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(1));

      const rewardList = await this.lockbox.connect(this.user1).getRewardList();
      expect(rewardList.length).to.equal(1);
   })

   it ('deploy expiration time and get rewards amount', async function () {
      await network.provider.send("evm_increaseTime", [1000 * 11]);
      await network.provider.send("evm_mine");
   
      const claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(0);

      const rewardList = await this.lockbox.connect(this.user1).getRewardList();
      expect(rewardList.length).to.equal(0);
   })

   it ('reclaim rewards', async function () {
      let oldBal = await this.rewardToken.balanceOf(this.lockbox.address);
      oldBal = smallNum(oldBal);

      await this.lockbox.connect(this.owner).reclaim_rewards();
      let newBal = await this.rewardToken.balanceOf(this.lockbox.address);
      newBal = smallNum(newBal);

      expect(oldBal - newBal).to.equal(1);
   })

   it ('claim rewards', async function () {
      await this.rewardToken.connect(this.deployer).transfer(this.lockbox.address, bigNum(10));
      await this.lockbox.connect(this.owner).give_reward(this.user1.address, bigNum(10), 0);
      const claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(10));

      const rewardList = await this.lockbox.connect(this.user1).getRewardList();
      expect(rewardList.length).to.equal(1);
      expect(smallNum(rewardList[0].rewardAmount)).to.equal(10);

      let oldBal = await this.rewardToken.balanceOf(this.user1.address);
      oldBal = smallNum(oldBal);

      await this.lockbox.connect(this.user1).claim_rewards();

      let newBal = await this.rewardToken.balanceOf(this.user1.address);
      newBal = smallNum(newBal);
      expect(newBal - oldBal).to.equal(10);
   })

   it ('set expiration time', async function () {
      await this.rewardToken.connect(this.deployer).transfer(this.lockbox.address, bigNum(10));
      await this.lockbox.connect(this.owner).give_reward(this.user1.address, bigNum(10), 0);

      await this.lockbox.connect(this.owner).setExpirationTime(20 * 1000);

      await network.provider.send("evm_increaseTime", [1000 * 11]);
      await network.provider.send("evm_mine");    

      let claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(10));

      await network.provider.send("evm_increaseTime", [1000 * 11]);
      await network.provider.send("evm_mine");    

      claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(0));
   })

   it ('get claimable reward when no reward', async function () {
      let claimableRewards = await this.lockbox.connect(this.user1).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(0));

      claimableRewards = await this.lockbox.connect(this.user2).getClaimableRewards();
      expect(claimableRewards).to.equal(bigNum(0));
   })
})