// SPDX-License_Identifier:MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract staking{

    IERC20 rewardToken;
    IERC20 stakingToken;


    uint256 rewardRate;
    uint256 public totalAmountStaked;
    uint256 public rewardPerToken;
    uint256 public lastUpdationTime;

    mapping(address=>uint256) public userRewardPerToken;
    mapping(address=>uint) public stakedAmount;
    mapping(address=>uint256) public rewards;

    constructor(uint256 _rewardRate,IERC20 _stakingTokenAddress,IERC20 _rewardTokenAddress){
        rewardRate=_rewardRate;
        rewardToken=_rewardTokenAddress;
        stakingToken=_stakingTokenAddress;
    }

// function to stake tokens and transfer to the contract address.
    function stakeTokens(uint256 _amount) public{
        require(_amount>0,"You need to stake atleast some amount");
        updateRewards(msg.sender);
        totalAmountStaked += _amount;
        stakedAmount[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

// function to unstake tokens of the required amount you want
    function unstakeTokens(uint256 _amount) public{
        require(stakedAmount[msg.sender]>=_amount,"Sorry, you don't have staked sufficient amount");
        updateRewards(msg.sender);
        totalAmountStaked -= _amount;
        stakedAmount[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

// function to claim the rewardTokens acccording to the staking time and amount staked.
    function claimRewards() public{
        updateRewards(msg.sender);
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
    }

//  function to update details after every change made to the staking contract.
    function  updateRewards(address _account) internal{
        rewardPerToken = rewardPerTokenStored();
        lastUpdationTime = block.timestamp;
        rewards[_account] = rewardsEarnedTillNow(msg.sender);
        userRewardPerToken[_account] = rewardPerToken ;
    }

//  function to calculate reward stored per token staked till current time. 
    function rewardPerTokenStored() internal view returns(uint256){
        if (totalAmountStaked == 0) 
        return rewardPerToken;
        return rewardPerToken + (((block.timestamp-lastUpdationTime)*rewardRate*10**18) / totalAmountStaked);
    }


// Function to get the amount of reward tokens earnerd till now.
    function rewardsEarnedTillNow(address _account) internal view returns(uint256){
        return ((stakedAmount[_account]*(rewardPerTokenStored()- userRewardPerToken[_account])) / 10**18) + rewards[_account] ;
    }
}