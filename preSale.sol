// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Contract to acepting USDC and transferring the MY Token
contract preSale is Ownable{

    address public Owner;
    IERC20 USDContract;
    IERC20 MyToken;    
    uint256 vestingTime;                  //time for which tokens are locked after purchase.  
    uint256 tokensSold;                                    
    uint256 totalTokenAvailableforSale;
    uint256 tempData;
    mapping(address=>address) referred;
    mapping(address=>uint256) public tokensPurchased;
    mapping(address=>uint256) public tokenWithdrawn;
    mapping(address=>uint256) buyTime;       //time at which USDC is sent buy a particular address.


    event TokensLocked(address indexed _buyer,uint256 indexed _tokenValue);
    event ReferralProcessed(uint256 indexed _USDCAmount,address _buyer);
    event WithdrawlDone(address indexed _buyer,uint256 _amount);

    constructor(IERC20 _USDCAddress, IERC20 MyTokenAddress, uint256 _vestingTime) Ownable(msg.sender){
        USDContract=_USDCAddress;
        MyToken=MyTokenAddress;
        totalTokenAvailableforSale=MyToken.totalSupply();
        vestingTime=_vestingTime;
        Owner=owner();
    }

// function to send USDC and get the MT token

    function purchase(uint256 _USDCAmount) public{

        require(msg.sender!=address(0),"Address(0) address can't buy token.");
        require(tokensPurchased[msg.sender]==0,"Sorry one use can purchase sale tokens once");
        uint256 requiredTokens=requiredMyTokens(_USDCAmount);
        // require(requiredTokens < 4000 ether,"Sorry one use can only buy at most of 4000 tokens");
        require(requiredTokens<=totalTokenAvailableforSale,"Sorry less tokens are available for sale.");
        require(USDContract.allowance(msg.sender,address(this))>=_USDCAmount,"Sorry you are not allowed to make this transfer");

        tokensSold+=requiredTokens;
        buyTime[msg.sender]=block.timestamp;                              //time at which tokens are bought
        totalTokenAvailableforSale-=requiredTokens;
        USDContract.transferFrom(msg.sender,address(this),_USDCAmount);
        tokensPurchased[msg.sender]+=requiredTokens;                      //these tokens will be unlocked after vesting period
    }

// Function for the referral purchase where user will pass the USDC amount and the address who has referred him.
    function referralPurchaseAndLock(uint256 _USDCAmount,address _referralAddress) public{
        require(tokensPurchased[_referralAddress]>0,"Sorry the referral address need to be the owner of the MyTokens");
        require(_referralAddress!=address(0),"Please provide a valid address");

        purchase(_USDCAmount);
        referred[msg.sender]=_referralAddress;                      // storing the address of the user who has referred the msg.sender
        emit TokensLocked(msg.sender, tokensPurchased[msg.sender]);
    }    

// function to get the MT tokens in exchange of USDC Amount according to the Sale Price Phase
    function requiredMyTokens(uint256 _USDCAmount) internal view returns(uint256){
        uint256 priceDecider=1+(tokensSold/(25000 ether));     // price decider will be 1 for 0-25k, 2 for 25k-50k, 3 for 50k-75k, 4 for 75k-100k tokens sold.
        if(priceDecider>4){
            priceDecider=4;
        }
        return ((4*_USDCAmount*10**18)/(10**6))/priceDecider;
    }

//function for the buyers to unlock their tokens and referral bonus after the vesting period is over
    function withdrawVestingFunds() public{
        // require(block.timestamp > buyTime[msg.sender]+vestingTime,"Sorry tokens are locked till the vesting period ends");
        require(tokensPurchased[msg.sender]>0,"Sorry you haven't locked any tokens till yet.");

        tempData=tokensPurchased[msg.sender];  // amount of  tokens locked.
        tokensPurchased[msg.sender]=0;
        tokenWithdrawn[msg.sender]+=tempData;
        MyToken.transferFrom(Owner,msg.sender, tempData);

        address previousReferredAddress=referred[msg.sender];
        uint8 variable=10;
        for(uint i=0;i<3;i++){
            if(previousReferredAddress!=address(0)){
                MyToken.transferFrom(Owner, previousReferredAddress,(variable*tempData/100));
            }
            else break;
            variable=variable/2;  //variable will be 10=>5=>2 for 3 intervals
            previousReferredAddress=referred[previousReferredAddress];
        }
        emit WithdrawlDone(msg.sender,tempData);
    }

// Function for owner to withdraw USDC at desired address
    function withdrawOwnerFunds() public onlyOwner{
        require(msg.sender==Owner," Only owner can withdraw the deposited USDC amount");
        USDContract.transfer(msg.sender,USDContract.balanceOf(address(this)));
    }

// function to check for the tokens left for sale.
    function totalTokensForSale() public view returns(uint256){
        return totalTokenAvailableforSale;
    }

}
