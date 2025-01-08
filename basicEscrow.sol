// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract escrow{

    //declaration of state variables
    address manager;
    struct Event{
        address sender;
        address receiver;
        uint256 amount;
        bool fundsLocked;
        bool fundsReleased;
        bool moneyWithdrawn;
        bool ticketRaised;
        bool ticketClosed;
    }
    uint256 eventNumber;
    mapping(uint256=>Event) eventList;

    constructor(){
        manager=msg.sender;
        eventNumber=1;
    }

    event eventRegistered(address indexed sender, address indexed receiver, uint256 indexed amount);
    event paymentLocked(uint256 indexed _eventNumber);
    event paymentReleased(uint256 indexed _eventNumber,address indexed sender);
    event fundsWithdrawn(uint256 indexed _eventNumber, address indexed receiver);
    event ticketRaised(uint256 indexed  _eventNumber, address indexed user);
    event IssueResolved(uint256 indexed _eventNumber);


// function for the manager to register the event for funds locking and transfer between two parties sender and receiver. Function will return the event number.  
    function registerEvent(address _sender, address _receiver, uint256 _amount) public returns(uint256){
        require(msg.sender==manager,"Only manager can register new event");
        Event memory e=Event(_sender, _receiver, _amount, false, false, false, false, false);
        eventList[eventNumber++]=e;
        emit eventRegistered(_sender, _receiver, _amount);
        return eventNumber-1;
    }

// function to lock the payment by the sender by sending the funds to the contract account.
    function lockPaymnet(uint256 _eventNumber) public payable{
        require(_eventNumber>0 && _eventNumber<eventNumber,"Please provide a valid event number");
        require(msg.sender==eventList[_eventNumber].sender,"Sorry, you are not allowed to lock the funds for this event");
        require(eventList[_eventNumber].fundsLocked==false,"Sorry the funds are already locked");
        require(msg.value==eventList[_eventNumber].amount,"Please pay the exact amount");

        eventList[_eventNumber].fundsLocked=true;
        emit paymentLocked(_eventNumber);
    }

// function for the sender of the money to release the payment to be withdrawn by the receiver once he gets the service or the assets.
    function releasePayment(uint256 _eventNumber) public{
        require(_eventNumber>0 && _eventNumber<eventNumber,"Please provide a valid event number");
        require(msg.sender==eventList[_eventNumber].sender,"Sorry, you are not allowed to release the funds for this event, only the sender can release the funds");
        require(eventList[_eventNumber].fundsLocked==true,"Sorry the funds are not locked, firstly lock the funds");
        require(eventList[_eventNumber].fundsReleased==false,"Soory, the funds are already release by you");

        eventList[_eventNumber].fundsReleased=true;
        emit paymentReleased(_eventNumber,msg.sender);
    }

// function for the receiver to withdraw the funds once those are released by the sender.
    function withdrawFunds(uint256 _eventNumber) public{
        require(_eventNumber>0 && _eventNumber<eventNumber,"Please provide a valid event number");
        require(msg.sender==eventList[_eventNumber].receiver,"Sorry, you are not the receiver of the funds");
        require(eventList[_eventNumber].fundsReleased==true,"Sorry, the funds are not released yet");
        require(eventList[_eventNumber].moneyWithdrawn==false,"Sorry, the funds are already withdrawn by you");

        eventList[_eventNumber].moneyWithdrawn=true;
        payable(msg.sender).transfer(eventList[_eventNumber].amount);
        emit fundsWithdrawn(_eventNumber, msg.sender);
    }

// function for both the sender and receiver to raise the issue ticket in case the sender do not release funds after receiving the service/assets or receiver has not provided the assets/service and sender want to refund the amount locked.
    function raiseIssueTicket(uint256 _eventNumber) public{
        require(_eventNumber>0 && _eventNumber<eventNumber,"Please provide a valid event number");
        require(eventList[_eventNumber].moneyWithdrawn==false,"Sorry, the funds are already withdrawn");
        require(msg.sender==eventList[_eventNumber].sender || msg.sender==eventList[_eventNumber].receiver,"Please, enter the correct address for either the receiver or the sender who has won the raised ticket");

        eventList[_eventNumber].ticketRaised=true;
        emit ticketRaised(_eventNumber, msg.sender);
    }

// function for the manager to send the funds to desired address after resolving the ticket issue.
    function makePaymentAfterIssue(uint256 _eventNumber, address _user) public{
        require(_eventNumber>0 && _eventNumber<eventNumber,"Please provide a valid event number");
        require(eventList[_eventNumber].ticketRaised==true,"Sorry, no ticket is raised for this event till now.");
        require(eventList[_eventNumber].ticketClosed==false,"The ticket is already closed and payment is made");
        require(_user==eventList[_eventNumber].sender || _user==eventList[_eventNumber].receiver,"Please, enter the correct address for either the receiver or the sender who has won the raised ticket");
        eventList[_eventNumber].ticketClosed=true;
        payable(_user).transfer(eventList[_eventNumber].amount);

        emit IssueResolved(_eventNumber);
    }
}