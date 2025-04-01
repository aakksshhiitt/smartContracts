// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract bank{

// declaring state variables
    address manager;

    mapping(address=>uint256) balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowed;
    mapping(address=>uint256) totalFundAllowed;
    constructor(){
        manager=msg.sender;
    }
    event fundDeposited(address indexed user,uint256 indexed amount);
    event fundTransferred(address indexed owner, address indexed to, uint256 indexed amount);
    event fundWithdrawn(address indexed owner, uint256 indexed amount);
    event Allowed(address indexed owner,address indexed spender);
    event allowanceRemoved(address indexed owner,address indexed spender);


// function to deposit funds in the bank smart contract
    function deposit() public payable{

        balanceOf[msg.sender]+=msg.value;
        emit fundDeposited(msg.sender, msg.value);
    }

// function for the users to chekc the balance
    function getBalance() public view returns(uint256){
        return balanceOf[msg.sender];
    }

// function for the user to withdraw the fund form the bank that is free and is not allowed further to any spender.
    function withdraw(uint256 _amount) public{
        require(balanceOf[msg.sender]>=_amount,"Sorry, you do not have the requested amount, please check the balance");
        require(balanceOf[msg.sender]>=totalFundAllowed[msg.sender]+_amount,"Please decrease the allowance and then withdraw the funds");
        balanceOf[msg.sender]-=_amount;
        payable(msg.sender).transfer(_amount);

        emit fundWithdrawn(msg.sender, _amount);
    }

// function for the user to transfer the fund to another address
    function transfer(address _to, uint256 _amount) public{
        require(balanceOf[msg.sender]>=_amount,"Sorry, you do not have the requested amount of fund, please check the balance");
        require(balanceOf[msg.sender]>=totalFundAllowed[msg.sender]+_amount,"Please decrease the allowance and then withdraw the funds");
        balanceOf[msg.sender]-=_amount;
        balanceOf[_to]+=_amount;
        payable(_to).transfer(_amount);

        emit fundTransferred(msg.sender, _to, _amount);
    }

// function for the user increase allowance so that the spender can transfer the specific amount. 
    function giveAccess(address _spender, uint256 _amount) public{
        require(totalFundAllowed[msg.sender]+_amount<=balanceOf[msg.sender],"Sorry, you are allowing more than your balance");
        allowed[msg.sender][_spender]+=_amount;
        totalFundAllowed[msg.sender]+=_amount;

        emit Allowed(msg.sender, _spender);
    }

// function to show the total allowance given.
    function showMyallowance() public view returns(uint256){
        return totalFundAllowed[msg.sender];
    }

// function to remove complete allowance from a particular spender
    function removeAccess(address _spender) public{
        require(allowed[msg.sender][_spender]>0,"The spender is already not given any allowance by you");
        totalFundAllowed[msg.sender]-=allowed[msg.sender][_spender];
        allowed[msg.sender][_spender]=0;
        emit allowanceRemoved(msg.sender, _spender);
    }

// function for the spender to transfer the amount form the owner to another address.
    function transferFrom(address _owner, address _to, uint256 _amount) public{
        require(allowed[_owner][msg.sender]>=_amount,"Sorry, you are not allowed by the owner to transfer this amount, increase the allowance");
        require(balanceOf[_owner]>=_amount,"Sorry, owner do not have the required amount of funds");
        
        balanceOf[_owner]-=_amount;
        balanceOf[_to]+=_amount;
        allowed[_owner][msg.sender]-=_amount;
        totalFundAllowed[_owner]-=_amount;
        payable(_to).transfer(_amount);

        emit fundTransferred(_owner, _to, _amount);
    }
}