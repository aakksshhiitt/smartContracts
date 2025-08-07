// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";



contract Wallet is Ownable, ReentrancyGuard {

    uint256 public rewardAPR;     // annual percentage return of tokens staked for 1 year, will be set by the owner
    uint256 public rewardRate;   // number of tokens given as reward per second
    bool public rewardActivation;

    
    address private constant SWAP_ROUTER_02 = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
    address private constant TokenA = 0x1781D77A7F74a2d0B55D37995CE3a4293203D3bc; 
    address public constant TokenB = 0xB59505810840F523FF0da2BBc71581F84Fc1f2B1; 
    address public constant TokenC = 0xb884F05Ca9c0b1d42FA7c446CF9f76be2bc4650E; 

    IV3SwapRouter public immutable swapRouter02 = IV3SwapRouter(SWAP_ROUTER_02);


    // address constant FACTORY_ADDRESS = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    uint24 public constant poolFee = 3000;

    address constant public ETH_ADDRESS= address(0);
    mapping(address=>mapping(address=>uint256)) public userHolding;
    mapping(address=>uint256) public ethBalance;
    mapping(address=>uint256) stakedAmount;
    mapping(address=>uint256) stakedTime;

    event Deposit(address indexed user, address indexed token, uint indexed amount);
    
    event Withdraw(address indexed user, address indexed token, uint indexed amount);

    event Transfer(address indexed to, address indexed token, uint indexed amount);

    constructor(uint256 _rewardPerETH) Ownable(msg.sender){
        rewardAPR=_rewardPerETH;
        rewardRate=(rewardAPR*10**18)/(365*24*3600);   // number of tokens given as reward per second according to the APR set by the owner
        rewardActivation=false;
    }

    function activateRewards() public onlyOwner{
        require(rewardActivation==false,"Rewars are already activated");
        rewardActivation=true;
    }

    function depositTokens(address _tokenAddress, uint256 _amount) public payable{           
        if (_tokenAddress==ETH_ADDRESS){
            require(_amount>0,"Amount should be greater than 0");
            require(msg.value==_amount,"Please pay the exact amount");
            ethBalance[msg.sender]+=_amount;
        }
        else{
            require(_amount>0,"Amount should be greater than 0");
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
            userHolding[msg.sender][_tokenAddress]+=_amount;
        }
        emit Deposit(msg.sender, _tokenAddress, _amount);
    }

    function withdrawFunds(address _tokenAddress, uint256 _amount) public nonReentrant{
         if (_tokenAddress==ETH_ADDRESS){
            require(fundsAvailableToWithdraw(msg.sender, ETH_ADDRESS)>=_amount,"You do not have the required fund available, please check the balance");
            ethBalance[msg.sender]-=_amount;
            payable(msg.sender).transfer(_amount);
        }
        else{
            require(fundsAvailableToWithdraw(msg.sender, _tokenAddress)>=_amount,"You do not have the required fund available, please check the balance");
            IERC20(_tokenAddress).transfer(msg.sender, _amount);
            userHolding[msg.sender][_tokenAddress]-=_amount;
        }
        emit Withdraw(msg.sender, _tokenAddress, _amount);
    }

    function transferTokens(address _tokenAddress, address _receiver, uint256 _amount) public{
        require(fundsAvailableToWithdraw(msg.sender, _tokenAddress)>=_amount,"You do not have the required fund available, please check the balance");
        userHolding[msg.sender][_tokenAddress]-=_amount;
        userHolding[_receiver][_tokenAddress]+=_amount;
        emit Transfer(_receiver, _tokenAddress, _amount);
    }

    function fundsAvailableToWithdraw(address _userAddress, address _tokenAddress) public view returns(uint256){
        if (_tokenAddress==ETH_ADDRESS){
            return ethBalance[_userAddress]-stakedAmount[msg.sender];
        }
        else return userHolding[_userAddress][_tokenAddress];

    }

    function swapTokens(address _tokenA, address _tokenB, uint256 amountIn) external returns (uint256 amountOut){
        require(userHolding[msg.sender][_tokenA]>=amountIn,"You do not have the required funds, please deposit the tokens first that you want to deposit");
        TransferHelper.safeApprove(_tokenA, address(swapRouter02), amountIn);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenA,
                tokenOut: _tokenB,
                fee: 3000,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter02.exactInputSingle(params);
        userHolding[msg.sender][_tokenA]-=amountIn;
        userHolding[msg.sender][_tokenB]+=amountOut;
    }

    function stakeFunds(uint256 _amount) public{
        require(rewardActivation==true,"Sorry the rewars are not activated by the owner till yet, you can stake after the activation");
        require(stakedAmount[msg.sender]==0,"You have already staked the tokens, if you want to restake then either wait for the staking period to be over or you can unstake and stake again");
        require(ethBalance[msg.sender]>=_amount,"You do not have the required fund available, please check the balance");
        stakedAmount[msg.sender]=_amount;
        stakedTime[msg.sender]=block.timestamp;
    }

    function showMyStakedAmount() public view returns(uint256){
        return stakedAmount[msg.sender];
    }

    function unstakeTokens() public{
        require(stakedAmount[msg.sender]>0,"Sorry, you haven't staked any tokens till yet");
        stakedAmount[msg.sender]=0;
        stakedTime[msg.sender]=0;
    }

    function checkRewardEarnedTillNow() public view returns(uint256){    
        require(rewardActivation==true,"Sorry the rewars are not activated by the owner till yet, you can stake after the activation");                       
        require(stakedAmount[msg.sender]>0,"Sorry, you haven't staked any funds");
        require(stakedTime[msg.sender]>0);
        return stakedAmount[msg.sender]*rewardRate*(block.timestamp-stakedTime[msg.sender]); 
    }

    function claimStakingRewards() public{
        require(rewardActivation==true,"Sorry the rewars are not activated by the owner till yet, you can stake after the activation");
        require(stakedAmount[msg.sender]>0,"Sorry, you haven't staked any funds");
        require(stakedTime[msg.sender]>0);
        // require(block.timestamp>stakedTime[msg.sender]+365*24*3600,"You can only claim the staked rewards after 1 year");
        uint256 amount=stakedAmount[msg.sender];
        uint256 time= stakedTime[msg.sender];
        stakedAmount[msg.sender]=0;
        stakedTime[msg.sender]=0;
        uint256 rewardAmount= (amount*rewardRate*(block.timestamp-time))/10**18; 
        userHolding[msg.sender][TokenC]+=rewardAmount;
        IERC20(TokenC).transferFrom(owner(),address(this),rewardAmount);
    }


       // function to withdraw the accidental sent funds
    function withdrawAllETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
