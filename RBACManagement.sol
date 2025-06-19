// SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RBACManager is AccessControl{

// declaring state variables

    struct Event{
        uint256 eventId;
        string  eventName;
        uint256 eventTime;
        uint256 endTime;
        uint256 totalParticipants;
        uint256 seatsLeft;
        bool completed;
    }

    mapping(uint256 => Event) eventList;     // event list that will store all the events created by the EDITOR_ROLE
    mapping(address=>mapping(uint256=>bool)) seatBooked;  //shows whether an address has booked a seat for particular event or not
    uint256 eventNumber;         // number represents the unique eventId

    bytes32 public constant EDITOR_ROLE= keccak256("EDITOR_ROLE");
    bytes32 public constant VIEWER_ROLE= keccak256("VIEWER_ROLE");

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);     // providing the deployer as the DEFAULT_ADMIN_ROLE
        eventNumber=1;
    }

// function for the DEFAULT_ADMIN_ROLE to change the admin of particular role
    function changeRoleAdmin(bytes32 _role, bytes32 _newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setRoleAdmin(_role, _newAdmin);
    }

// function for the DEFAULT_ADMIN_ROLE to grant EDITOR_ROLE role to an address
    function grantEditorRole(address user) public onlyRole(getRoleAdmin(EDITOR_ROLE)) {
        _grantRole(EDITOR_ROLE, user);
    }

// function for the DEFAULT_ADMIN_ROLE to grant VIEWER_ROLE role to an address
    function grantViewerRole(address user) public onlyRole(getRoleAdmin(VIEWER_ROLE)) {
        _grantRole(VIEWER_ROLE, user);
    }

// function for the EDITOR_ROLE to add the event details
    function addEvent(string memory _eventName, uint256 _eventTime, uint256 _endTime, uint256 _totalParticipants) public onlyRole(EDITOR_ROLE){
        require(_eventTime>=block.timestamp + 2 days,"You need to register the event at least 2 days before the event");
        require(_endTime>_eventTime,"Endtime must be greater than event start time");
        Event memory e=Event(eventNumber, _eventName, _eventTime, _endTime, _totalParticipants, _totalParticipants, false);
        eventList[eventNumber++]=e;
        // emit eventRegistered()
    }

// function for the EDITOR_ROLE to edit the event details that is already registered
    function editEvent(uint256 _eventId,string memory _eventName, uint256 _eventTime, uint256 _endTime, uint256 _totalParticipants) public onlyRole(EDITOR_ROLE){
        require(block.timestamp<=eventList[_eventId].eventTime,"You have to edit the event details before the event start");
        require(_eventTime>=block.timestamp + 2 days,"You need to register the event at least 2 days before the event");
        require(_endTime>_eventTime,"Endtime must be greater than event start time");
        eventList[_eventId].eventName=_eventName;
        eventList[_eventId].eventTime=_eventTime;
        eventList[_eventId].endTime=_endTime;
        eventList[_eventId].totalParticipants=_totalParticipants;
        eventList[_eventId].completed=false;
    }

// function for the EDITOR_ROLE to mark a particular event as completed
    function markEventAsCompleted(uint256 _eventId) public onlyRole(EDITOR_ROLE){
        require(!eventList[_eventId].completed,"This event has already been completed.");
        require(block.timestamp>=eventList[_eventId].endTime,"Sorry, the event is not completed yet");
        eventList[_eventId].completed=true;
    }

//  function for all the users that are provided with any role to check the event details
    function viewEventDetails(uint256 _eventId) public view returns(Event memory){
        require(hasRole(VIEWER_ROLE, msg.sender) || hasRole(EDITOR_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),"Sorry, you don't have any assigned role to access this function");
        return eventList[_eventId];
    }

//  function for all the users that are provided with any role to book the seat for a particular event
    function bookSeats(uint256 _eventId) public{
        require(hasRole(VIEWER_ROLE, msg.sender) || hasRole(EDITOR_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),"Sorry, you don't have any assigned role to access this function");
        require(eventList[_eventId].completed==false,"This event has already been completed.");
        require(eventList[_eventId].seatsLeft>=1, "There are no seats left.");
        require(seatBooked[msg.sender][_eventId]==false,"You have already booked the seat for this event");
        eventList[_eventId].seatsLeft--;
        seatBooked[msg.sender][_eventId]=true;
    }

    

}