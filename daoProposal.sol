// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract DAO{

// declaring staate variables
    address manager;
    struct Member{
        address memberAddress;
        uint256 time;
        uint256 tokenBalance;
    }
    struct Proposal{
        string description;
        uint256 voteCount;
        bool executed;
    }

    uint256 totalTokenSupply;
    uint256 proposalNumber;
    mapping(address=>uint256) balanceOf;
    mapping(address=>Member) memberList;
    mapping(uint256=>Proposal) proposalList;
    mapping(address=>mapping(uint256=>bool)) hasVoted;
    
    constructor(){
        manager=msg.sender;
        totalTokenSupply=0;
        proposalNumber=1;
    }
// modifiers
    modifier onlyManager(){
        require(msg.sender==manager,"Sorry, only manager can access this functionality");
        _;
    }
    modifier onlyMember(){
        require(memberList[msg.sender].memberAddress!=address(0),"Sorry you are not a member so you can't access this functionality");
        _;
    }

    event memberAdded(address indexed memberAddress, uint256 time);
    event memberRemoved(address indexed memberAddress, uint256 indexed time);
    event proposalCreated(uint256 indexed proposalNumber);
    event voteMade(address indexed voter);
    event ProposalExecuted(bool indexed result);


// function for the manager to add the member 
    function addMember(address _memberAddress) public onlyManager{
        require(_memberAddress!=address(0),"Please provide a valid address");
        require(memberList[_memberAddress].memberAddress==address(0),"Sorry the member is already regostered");
        Member memory m=Member(_memberAddress, block.timestamp, 100);
        balanceOf[_memberAddress]=100;
        memberList[_memberAddress]=m;
        totalTokenSupply+=100;

        emit memberAdded(_memberAddress, block.timestamp);
    }

// function to remove the member using the member address.
    function removeMember(address _memberAddress) public onlyManager{
        require(memberList[_memberAddress].memberAddress!=address(0),"Sorry this candidate do not exist");
        memberList[_memberAddress].memberAddress=address(0);
        memberList[_memberAddress].tokenBalance=0;
        memberList[_memberAddress].time=0;
        totalTokenSupply-=balanceOf[_memberAddress];
        balanceOf[_memberAddress]=0;

        emit memberRemoved(_memberAddress, block.timestamp);
    }

// function for the manager to create proposal so that the members can vote for that.
    function createProposal(string memory _description) public onlyManager{
        Proposal memory p=Proposal(_description, 0, false);
        proposalList[proposalNumber++]=p;

        emit proposalCreated(proposalNumber-1);
    }

// function for the members to check the proposal details.
    function checkProposalDetails(uint256 _proposalNumber) public view onlyMember returns(Proposal memory){
        require(_proposalNumber>0 && _proposalNumber<proposalNumber,"Please provide a valide proposalNumber");
        return proposalList[_proposalNumber];
    }

// function for the member to check the  governance token balance left 
    function checkMyTokenBalance() public view onlyMember returns(uint256){
        return balanceOf[msg.sender];
    }

// function for the members to vote for a particular proposal with any number of governance tokens they want to stake and increase the weightage for that proposal. Minimum 10% of vots are required.
    function voteProposal(uint256 _proposalNumber, uint256 _stakeTokenCount) public onlyMember{
        require(_proposalNumber>0 && _proposalNumber<proposalNumber,"Please provide a valide proposalNumber");
        require(proposalList[_proposalNumber].executed==false,"Sorry, the proposal is already comepleted");
        require(hasVoted[msg.sender][_proposalNumber]==false,"Sorry, you have already voted for this proposal");
        require(_stakeTokenCount>0,"Please stake some tokens for voting");
        require(balanceOf[msg.sender]>=_stakeTokenCount,"Sorry you do not have the required amount of tokens that you want to stake for voting");
        
        balanceOf[msg.sender]-=_stakeTokenCount;
        memberList[msg.sender].tokenBalance-=_stakeTokenCount;
        proposalList[_proposalNumber].voteCount+=_stakeTokenCount;
        hasVoted[msg.sender][_proposalNumber]=true;

        emit voteMade(msg.sender);
    }

//  function for the manager to execute the proposal.
// the proposal will only be executed if the staked tokens are more than 10% of total governance tokens.
    function executeProposal(uint256 _proposalNumber) public onlyManager{
        require(_proposalNumber>0 && _proposalNumber<proposalNumber,"Please provide a valide proposalNumber");
        require(proposalList[_proposalNumber].executed==false,"Sorry, the proposal has already been completed");
        require(proposalList[_proposalNumber].voteCount>totalTokenSupply/10,"Sorry, the majority of the votes are not with this proposal");
        proposalList[_proposalNumber].executed=true;

        emit ProposalExecuted(true);
    }
}

