// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract presale{

// declaring state variables
    address public owner;
    uint256 public totalTokensForSale;
    uint256 public tokensLeftForSale;
    uint256 public vestingPeriod;
    uint256 public tokensSold;
    uint256 public ownerFunds;
    bool public USDCAddressSet;
    IERC20 RewardToken;     // Contract address for the reward token
    IERC20 public USDCToken;      // contract address for the USDC token to make the payment

    mapping(address=>uint256) public stakedAmount;
    mapping(address=>uint256) public stakedTime;
    mapping(address=>uint256) public rewardTokensOf;
    mapping(address=>bool) public rewardsClaimed;
    mapping(address=>address) public referred;

    constructor(uint256 _rewardTokenSupply, uint256 _totalTokensForSale, uint256 _vestingPeriod){
        owner=msg.sender;
        totalTokensForSale=_totalTokensForSale;
        tokensLeftForSale=_totalTokensForSale;
        vestingPeriod=_vestingPeriod;
        tokensSold=0;
        USDCAddressSet=false;
        
        RewardCoin r=new RewardCoin(_rewardTokenSupply);  // initiating the Reward Coin contract
        RewardToken=r;
    }

    modifier onlyOwner{
        require(msg.sender==owner,"Only owner can access this functionality");
        _;
    }
    modifier onlyBuyer{
        require(stakedAmount[msg.sender]>0,"Only the users that have vested in the token can access this functionality");
        _;
    }

// function to set the contract address of the USDC contract that will be staked.
// USDC contract can be set only once.
    function SetUSDCContract(IERC20 _USDCAddress) public onlyOwner{
        require(USDCAddressSet==false,"Sorry, the USDC token address is already set");
        USDCToken=_USDCAddress;
        USDCAddressSet=true;
    }

// function for everyone to stake the usdc after approving the contract to tramsfer the specific USDC tokens.
    function purchaseAndLock(uint256 _USDCAmount) public{
        require(msg.sender!=address(0),"You are not allowed to stake the tokens");
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can stake");
        require(_USDCAmount>0,"Please stake some USDC");
        require(stakedAmount[msg.sender]==0,"Sorry you have already staked the USDC");
        require(rewardsClaimed[msg.sender]==false,"You have already claimed the rewards");
        require(USDCToken.allowance(msg.sender, address(this))>=_USDCAmount,"Please provide the allowance to the contract");
        require(USDCToken.balanceOf(msg.sender)>=_USDCAmount,"Sorry, you do not have the required USDC tokens");
        uint256 requiredRewardTokens=calculateRewardTokens(_USDCAmount);
        require(tokensLeftForSale>=requiredRewardTokens,"Sorry less tokens are left for sale, try to stake less amount");
        
        rewardTokensOf[msg.sender]=requiredRewardTokens;
        tokensLeftForSale-=requiredRewardTokens;
        tokensSold+=requiredRewardTokens;
        stakedAmount[msg.sender]=_USDCAmount;
        stakedTime[msg.sender]=block.timestamp;
        USDCToken.transferFrom(msg.sender,address(this),_USDCAmount);
    }

// function for the users to purchase the tokens and refer the user that has already claimed the rewards.
// referral rewards will be till 3 hierarchical level, ie. 10%, 5%, 2%
    function referralPurchaseLock(uint256 _USDCAmount, address _referralAddress) public{
        require(rewardsClaimed[_referralAddress]==true,"Sorry, the referral address has not claimed the tokens yet");
        require(_referralAddress!=address(0),"Please provide a valid address");
        purchaseAndLock(_USDCAmount);
        referred[msg.sender]=_referralAddress;
    }

// function for the buyers to withdraw the staked amount before the vesting period.
    function withdrawBeforeTime() public onlyBuyer{
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        require(stakedAmount[msg.sender]>0,"Sorry, you do not have staked any amount");
        // require(block.timestamp<stakedTime[msg.sender] + vestingPeriod * 24*60*60,"You have completed the staking time, click on claimVesting rewards and get the reward tokens");

        uint256 refundAmount=stakedAmount[msg.sender];
        tokensLeftForSale+=rewardTokensOf[msg.sender];
        tokensSold-=rewardTokensOf[msg.sender];
        rewardTokensOf[msg.sender]=0;
        stakedAmount[msg.sender]=0;
        stakedTime[msg.sender]=0;
        
        USDCToken.transfer(msg.sender, refundAmount);
    }

// function for the buyers to clim the reward after the vesting period is over.
    function claimRewards() public{
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        require(rewardsClaimed[msg.sender]==false,"Sorry, you have already claimed the rewards");
        require(stakedAmount[msg.sender]>=0,"Sorry, you haven't staked any funds");
        require(stakedAmount[msg.sender]>0,"Only the users that have vested in the token can access this functionality");

        // require(block.timestamp>=stakedTime[msg.sender] + vestingPeriod * 24*60*60, "Sorry, the staking time is not completed yet, you can only claim the rewards after the staking period of 100 days is over");
        
        uint256 rewardAmount=rewardTokensOf[msg.sender];
        address previousRefferedAddress=referred[msg.sender];
        uint8 percentage=10;

        ownerFunds+=stakedAmount[msg.sender];
        rewardTokensOf[msg.sender]=0;
        stakedAmount[msg.sender]=0;
        stakedTime[msg.sender]=0;
        rewardsClaimed[msg.sender]=true;

        RewardToken.transfer(msg.sender, rewardAmount);
        for(uint8 i=0;i<3;i++){
            if(previousRefferedAddress!=address(0)){
                RewardToken.transfer(previousRefferedAddress,(percentage*rewardAmount)/100);
            }
            else break;
            percentage=percentage/2;
            previousRefferedAddress=referred[previousRefferedAddress];
        }
    }

// function for the Owner to withdraw the USDC amount staked and claimed
    function withdrawUSDC() public onlyOwner{
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        require(ownerFunds>0,"Sorry, no fund is available to be withdrawn");
        USDCToken.transfer(owner,ownerFunds);
        ownerFunds=0;
    }

// function(Internal) to calculate the reward tokens that will be given to stake _USDCAmount.
    function calculateRewardTokens(uint256 _USDCAmount) internal view returns(uint256){
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        uint256 priceDecider=1 + (tokensSold/250000 ether);
        if(priceDecider>4){
            priceDecider=4;
        }
        return (4*_USDCAmount*10**18)/((10**6)*priceDecider);
    }

// function for the buyers to check their vestedAmount.
    function checkMyVestedAmount() public view returns(uint256){
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        return stakedAmount[msg.sender];
    }

// function for everyone to check the reward tokens that will be given to stake _USDCAmount.
    function checkRewardAmount(uint256 _USDCAmount) public view returns(uint256){
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        return calculateRewardTokens(_USDCAmount);
    }

    function myRewardBalance() public view returns(uint256){
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        return RewardToken.balanceOf(msg.sender);
    }

    function timeLeft() public view onlyBuyer returns(uint256){
        require(USDCAddressSet==true,"Please let the owner set the USDC adderss first so that you can access the functionality");
        if(vestingPeriod*60*60*24-(block.timestamp-stakedTime[msg.sender])>0)
        return vestingPeriod*60*60*24-(block.timestamp-stakedTime[msg.sender]);
        else
        return 0;
    }

}

// contract of the Reward Coin that will be automatically deployed by the constructor of the presale contract.
contract RewardCoin is ERC20, Ownable {
    address initialOwner;
    uint256 initialSupply;
    constructor(uint256 _totalSupply) ERC20("RewardToken","RT") Ownable(msg.sender){
        _mint(msg.sender ,_totalSupply);  // transferring the tokens to the calling contract
    }
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

//user can stake the USDC funds  for 100 days and get the reward tokens
// user can withdraw the staked amount USDC within 100 days
// AFter 100 days of staking user can only get the reward tokens he is eligible for.
// owner can only withdraw the USDC for which the rewards have been given.
// for first 250000 reward tokens 1USDC=4Reward tokens, for reward tokens from 250k-500k 1USDC=2 Reward tokens, for 500k-750k 1USDC=4/3 reward tokens and further 1USDC=1Reward token
// referral address should have claimed the rewards before.
// referral rewards will be till 3 hierarchical level, ie. 10%, 5%, 2%
// The person that has claimed hte rewars once is not allowed to purchase the reward tokens again.