// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract eventManagement{
// state variables declaration 
    address manager;
    struct Event{
        string eventName;
        address eventOrganizer;
        uint ticketPrice;
        uint totalSeats;
        uint seatsLeft;
        uint eventTime;
    }
    uint eventNumber=1;
    mapping(uint=>Event) eventList;    
// constructor 
    constructor(){
        manager=msg.sender;
    }
// events declaration 
    event eventCreated(uint indexed _eventNumber,uint indexed _eventTime);
    event ticketBought(address indexed _buyer,uint indexed _eventNumber,uint indexed _ticketCount);

// function to register new events a week before
    function createEvent(string memory _eventName,address _organizer,uint _price,uint _totalTickets,uint _eventTime) public{
        require(msg.sender==manager,"Only manager can register a new event");
        require(_eventTime>block.timestamp + 7 days,"Sorry event time must be after 1 day of creation");
        Event memory e=Event(_eventName,_organizer,_price,_totalTickets,_totalTickets,_eventTime);
        eventList[eventNumber++]=e;
        emit eventCreated(eventNumber,_eventTime);
    }

// function to buy tickets for particular event
    function buyTickets(uint _eventNumber,uint _ticketCount) public payable{
        require(_eventNumber>1 && _eventNumber<=eventNumber,"No event available for this event number");
        require(block.timestamp<eventList[_eventNumber].eventTime - 1 days,"Sorry ticket booking for this event is closed");
        require(eventList[_eventNumber].seatsLeft>=_ticketCount,"Sorry less number of tickets are left");
        require(msg.value==eventList[_eventNumber].ticketPrice*_ticketCount,"Please pay the exact amount");
        eventList[_eventNumber].seatsLeft-=_ticketCount;
        emit ticketBought(msg.sender,_eventNumber,_ticketCount);
    }

// function to show event related details
    function showEventDetails(uint _eventNumber) public view returns(Event memory){
        require(_eventNumber>0 && _eventNumber<=eventNumber,"No event available for this event number");
        return eventList[_eventNumber];
    }

}