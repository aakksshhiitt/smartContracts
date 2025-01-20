import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

// airdrop contract
contract airDrop{

//declaring state variables
    address manager;
    struct User{
        string name;
        uint8 age;
        uint256 govtIdNumber; 
        address recepientAddress;
    }
    uint public minimumStakeAmount;
    mapping(address=>User) userList;
    mapping(address=>uint256) stakedFunds;
    mapping(address=>uint256) stakedTime;
    mapping(address=>bool) alreadyStaked;
    IERC20 AirDropToken;

// constructor 
    constructor(uint256 _totalSupply, uint256 _minimumStakeAmount){
        RewardToken _AirDropToken=new RewardToken(_totalSupply);
        AirDropToken=_AirDropToken;
        manager=msg.sender;
        minimumStakeAmount=_minimumStakeAmount;
    }

// event declaration
    event AmountStaked(address indexed user, uint256 indexed stakeTime);
    event UserAdded(address indexed _recepientAddress);
    event FundsWithdrawn(address indexed _user, uint256 indexed _time);
    event AirdropGiven(address indexed _user, uint256 indexed _rewardAmount);

// function for the users to stake their funds for the airdrop
    function stakeFunds() public payable{
        require(userList[msg.sender].recepientAddress!=address(0),"Please add the user details to continue with the staking process");
        require(alreadyStaked[msg.sender]==false,"You have already staked, you can withdraw and make new staking");
        require(msg.value>=minimumStakeAmount,"Please stake atleast amount required for airdrop");
        stakedFunds[msg.sender]=msg.value;
        stakedTime[msg.sender]=block.timestamp;
        alreadyStaked[msg.sender]=true;

        emit AmountStaked(msg.sender, block.timestamp);
    }

// function for the users to add the details.
    function addYourDetails(string memory _name, uint8 _age, uint256 _govtIdNumber) public{
        require(userList[msg.sender].recepientAddress==address(0),"User already exist");
        User memory u=User(_name, _age, _govtIdNumber, msg.sender);
        userList[msg.sender]=u;

        emit UserAdded(msg.sender);
    }

// function for the users to withdraw the staked amount before the airdrop period
    function withdrawFunds() public{
        require(stakedFunds[msg.sender]>0,"Sorry you have not staked any amount");
        require(block.timestamp<stakedTime[msg.sender] + 100*24*60*60,"Sorry the staked amount is completed, you can claim the airdrop and withdraw the funds");
        uint256 refundAmount=stakedFunds[msg.sender];
        stakedFunds[msg.sender]=0;
        stakedTime[msg.sender]=0;
        alreadyStaked[msg.sender]=false;
        userList[msg.sender].recepientAddress=address(0);
        payable(msg.sender).transfer(refundAmount);

        emit FundsWithdrawn(msg.sender, block.timestamp);
    }

// function to claim the airdrop and get the staked amount back.
    function getAirdropTokens() public{
        require(stakedFunds[msg.sender]>=minimumStakeAmount,"Sorry you have not staked any amount for the airdrop");
        require(block.timestamp>stakedTime[msg.sender]+100*24*60*60,"You can only claim the airdrop after 100 days of amount staked");
        
        uint256 rewardAmount=calculateRewards(stakedFunds[msg.sender]);
        AirDropToken.transfer(msg.sender,rewardAmount);
        
        uint256 refundAmount=stakedFunds[msg.sender];
        stakedFunds[msg.sender]=0;
        stakedTime[msg.sender]=0;
        alreadyStaked[msg.sender]=false;
        userList[msg.sender].recepientAddress=address(0);
        payable(msg.sender).transfer(refundAmount);

        emit AirdropGiven(msg.sender,rewardAmount);
    }

// function to calculate the airdrop rewards, for 1 ether 1 million of airdrop tokens will be given.
    function calculateRewards(uint256 _stakedAmount) internal pure returns(uint256){
        return (1000000*_stakedAmount*10**18)/10**18;
    }  
}


// reward token contract
contract RewardToken is ERC20{
    constructor(uint256 _totalSupply) ERC20("RewardToken","RT"){
        _mint(msg.sender,_totalSupply);  // transferring the tokens to the calling contract
    }
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}