// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

contract ticketBooking{    
// declaring state variables
    address manager;
    struct route{
        address owner;
        string from;
        string to;
        uint departureTime;
        uint ticketPrice;
        uint totalTickets;
        uint seatsLeft;
    }
    uint routeNumber;
    mapping(uint=>route) routeList;
    mapping(address=>mapping(uint=>uint)) myTickets;  //tickets bought by user for particular route
    constructor(){
        manager=msg.sender;
        routeNumber=1;
    }

    event routeRegistered(string indexed _from,string indexed _to);
    event ticketsBought(address indexed _buyer,uint indexed _routeNumber,uint indexed _numberOfTickets);
    event bookingCanceled(address indexed _buyer,uint indexed _routeNumber);
    event tourComplete(uint indexed _routeNumber);

// function to register a new route
    function registerNewRoute(address _owner,string memory _from,string memory _to,uint _departureTime,uint _price,uint _totalTickets) public{
        require(msg.sender==manager,"Only manager can add a new route");
        require(_departureTime>= block.timestamp + 7 days,"You need to register a route before 7 days");
        require(_totalTickets>0 && _price>0);
        require(_owner!=address(0),"Provide a valid owner");
        route memory r=route(_owner,_from,_to,_departureTime,_price,_totalTickets,_totalTickets);
        emit routeRegistered(_from,_to);
        routeList[routeNumber++]=r;
    }

// function for buyers to buy tickets for particular route
    function buyTickets(uint _routeNumber,uint _ticketsCount) public payable{
        require(msg.sender!=manager,"Manager can't buy tickets");
        require(_routeNumber>0 && _routeNumber<routeNumber,"Provide a valid route");
        require(routeList[_routeNumber].seatsLeft>=_ticketsCount,"Sufficient seats not available");
        require(msg.value==routeList[_routeNumber].ticketPrice*_ticketsCount,"Please pay exact amount");
        routeList[_routeNumber].seatsLeft-=_ticketsCount;
        myTickets[msg.sender][_routeNumber]+=_ticketsCount;
        emit ticketsBought(msg.sender,_routeNumber,_ticketsCount);
    }

// function to cancel the booking done buy the buyers and get the instant refund
    function cancelBooking(uint _routeNumber) public{
        require(myTickets[msg.sender][_routeNumber]>0,"Sorry you haven't bought any tickets for this route");
        require(block.timestamp<=routeList[_routeNumber].departureTime + 1 days,"Sorry you can only refund before 1 day of departure");
        routeList[_routeNumber].seatsLeft+=myTickets[msg.sender][_routeNumber];
        uint myTicketCount=myTickets[msg.sender][_routeNumber];
        myTickets[msg.sender][_routeNumber]=0;
        payable(msg.sender).transfer(routeList[_routeNumber].ticketPrice*myTicketCount);
        emit bookingCanceled(msg.sender,_routeNumber);
    }
// function to get the route details
    function getRouteDetails(uint _routeNumber) public view returns(route memory){
        require(_routeNumber>0 && _routeNumber<routeNumber,"Provide a valid route");
        return routeList[_routeNumber];
    }

// function for the owner to mark the tour as complete and get the payment
    function tourCompleted(uint _routeNumber) public{
        require(msg.sender==routeList[_routeNumber].owner,"Only owner of route can access");
        require(block.timestamp>=routeList[_routeNumber].departureTime + 1 days,"You can get the fund after 1 day of departure");
        uint amount=routeList[_routeNumber].ticketPrice*(routeList[_routeNumber].totalTickets-routeList[_routeNumber].seatsLeft);   
        routeList[_routeNumber].seatsLeft=0;
        payable(msg.sender).transfer(amount);
        emit tourComplete(_routeNumber); 
    }
}