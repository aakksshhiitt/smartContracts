// SPDX-License-Identifier:MIT
pragma solidity ^0.8.28;

contract multiSignWallet{

    address manager;
    struct Transaction{
        uint256 transactionId;
        address to;
        uint256 amount;
        bool completed;
        mapping(address=>bool) confirmed;
    }
    address[] owners;
    mapping(address=>bool) ownerExist;
    mapping(uint256=>Transaction) public transactionList;
    uint256 transactionId;
    constructor(){
        manager=msg.sender;
        transactionId=1;
    }

    modifier onlyManager{
        require(msg.sender==manager,"Sorry, only manager can access this feature");
        _;
    }

// declaring events
    event transactionRegistered(address indexed to, uint256 indexed amount);
    event ownerAdded(address indexed ownerAddress);
    event transactionApproved(uint256 indexed transactionId, address indexed _ownerAddress);
    event transactionCompleted(uint256 indexed transactionId);

//function for the manager to register the transaction
    function registerTransaction(address _to, uint256 _amount) public onlyManager{
        Transaction storage t=transactionList[transactionId];
        t.transactionId=transactionId++;
        t.to=_to;
        t.amount=_amount;
        t.completed=false;
        emit transactionRegistered(_to, _amount);
    }

// function to check if the transaction is completed or not
    function isTransactionCompleted(uint256 _transactionId) public view returns(bool){
        require(_transactionId>0 && _transactionId<transactionId,"Please enter a valid transaction id");
        if(transactionList[_transactionId].completed==true)
        return true;
        return false;
    }

// function for the manager to register new owner
    function registerOwner(address _ownerAddress) public onlyManager{
        require(ownerExist[_ownerAddress]==false,"Sorry, this owner already exist");
        owners.push(_ownerAddress);
        ownerExist[_ownerAddress]=true;
        emit ownerAdded(_ownerAddress);
    }

// function for the owners to approve the transaction
    function approveTransaction(uint256 _transactionId) public{
        require(transactionList[_transactionId].completed==false,"Sorry, the transaction is already approved and completed");
        require(_transactionId>0 && _transactionId<transactionId,"Please enter a valid transaction id");
        require(transactionList[_transactionId].confirmed[msg.sender]==false,"Sorry, the transaction is already approved by you.");
        require(ownerExist[msg.sender]==true,"Sorry, you are not one of the owner so, you are not allow to approve the transaction");
        transactionList[_transactionId].confirmed[msg.sender]=true;
        emit transactionApproved(_transactionId, msg.sender);
    }

// function for any of the owner to make the payment for particular transaction id by paying the exact amount if all the owners have approved the transaction.
    function makePayment(uint256 _transactionId) public payable{
        require(transactionList[_transactionId].completed==false,"Sorry, the transaction is already approved and completed");
        require(_transactionId>0 && _transactionId<transactionId,"Please enter a valid transaction id");
        require(msg.value==transactionList[_transactionId].amount,"Please pay the exact amount for the transaction");
        require(ownerExist[msg.sender]==true,"You are not the owner, so you can't make the transaction");

        bool flag=true;
        for(uint i=0;i<owners.length;i++){
            if(transactionList[_transactionId].confirmed[owners[i]]==false){
                flag=false;
            }
        }
        require(flag==true,"Please check if all the owners have approved the transaction");
        transactionList[_transactionId].completed=true;
        payable(transactionList[_transactionId].to).transfer(transactionList[_transactionId].amount);

        emit transactionCompleted(_transactionId);
    }
}