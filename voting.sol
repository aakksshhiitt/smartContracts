// SPDX-License-Identifer:MIT
pragma solidity ^0.8.17;
contract voting{

//declaring state variables 
    address manager;
    struct candidate{
        address candidateAddress;
        string name;
        uint age;
        string homeAddress;
        uint votesCount;
    }
    uint votingTime;
    uint candidateCount;
    mapping(uint=>candidate) candidateList;
    mapping(address=>bool) candidateExist;
    mapping(address=>bool) alreadyVoted;
    candidate[] winnerCandidate;
//constructor  
    constructor(uint _votingTime){
        manager=msg.sender;
        votingTime=_votingTime;
        candidateCount=1;
    }
//events declaration 
    event candidateRegistered(address indexed _candidateAddress,string indexed _name);
    event votingDone(address indexed _voter);
    event resultDeclared(candidate[] indexed _winner);

// function to register a new candidate for election
    function registerCandidate(address _candidateAddress,string memory _name,uint _age,string memory _homeAddress) public{
        require(msg.sender==manager,"Only manager can register new candidate");
        require(block.timestamp<votingTime - 1 days,"Sorry you can only register candidates only till one day before voting starts");
        require(candidateExist[_candidateAddress]==false,"Sorry this candidate is already registered");
        candidate memory c=candidate(_candidateAddress,_name,_age,_homeAddress,0);
        candidateList[candidateCount++]=c;
        candidateExist[_candidateAddress]=true;
        emit candidateRegistered(_candidateAddress,_name);
    }

// function to get the name of particular candidate number
    function showCandidate(uint _candidateNumber) public view returns(string memory){
        require(_candidateNumber<=candidateCount && _candidateNumber!=0,"Sorry this candidate doesn't exist");
        return candidateList[_candidateNumber].name;
    }

// function for voting a particular candidate
    function voteCandidate(uint _candidateNumber) public{
        require(block.timestamp>votingTime,"Voting not started yet");
        require(block.timestamp<votingTime + 1 days,"Sorry voting time is over");
        require(alreadyVoted[msg.sender]==false,"Sorry you have already voted");
        require(_candidateNumber<=candidateCount && _candidateNumber!=0,"Sorry this candidate doesn't exist");
        alreadyVoted[msg.sender]=true;
        candidateList[_candidateNumber].votesCount++;
        if(winnerCandidate.length==0){
            winnerCandidate.push(candidateList[_candidateNumber]);
        }
        else if(candidateList[_candidateNumber].votesCount==winnerCandidate[0].votesCount){
            winnerCandidate.push(candidateList[_candidateNumber]);
        }
        else if(candidateList[_candidateNumber].votesCount>winnerCandidate[0].votesCount){
            delete winnerCandidate;
            winnerCandidate.push(candidateList[_candidateNumber]);
        }
        else return;
        
        emit votingDone(msg.sender);
    }

// result declaration function returning the highest vote getter(s)
    function declareResults() public returns(candidate[] memory){
        require(msg.sender==manager,"Only manager can declare results");
        require(block.timestamp>votingTime + 1 days,"Sorry voting is not over yet");
        emit resultDeclared(winnerCandidate);
        return winnerCandidate;
    }
}