// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract lottery{

// declaring state variables
    address manager;
    uint deployTime;

    constructor(){
        manager=msg.sender;
        deployTime=block.timestamp;
    }

    address[] buyers;
    event ticketBought(address indexed buyer);
    event resultDeclared(address indexed winner,uint indexed amount);

// function to get entry to the lottery
    function buyLotteryTicket() public payable{
        require(msg.sender!=manager,"Manager can't buy a lottery ticket");
        require(block.timestamp<=deployTime + 7 days,"Sorry time is over");
        require(msg.value == 1 ether,"Please pay exact one ether");
        buyers.push(msg.sender);
        emit ticketBought(msg.sender);
    }

// declaration of the lottery results
    function declareResults() public{
        require(msg.sender==manager,"Only manager can declare the results");
        require(block.timestamp>deployTime+ 7 days,"Sorry buying time is not over yet");

        // this random number can be insecure so you can use chainlink vrf for security
        uint randomNumber=uint256(sha256(abi.encodePacked(block.number,block.difficulty)))%buyers.length;
        emit resultDeclared(buyers[randomNumber],address(this).balance);
        payable(buyers[randomNumber]).transfer(address(this).balance);
    }
}