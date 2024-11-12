// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract loan{

    address public manager;
    constructor(){
        manager=msg.sender;
    }
    struct loanTerms{
        address lender;
        address borrower;
        uint lendingDate;
        uint loanAmount;
        uint timePeriod;
        bool loanPaid;
    }
    uint loanNumber;
    mapping(uint=>loanTerms) public loanList;
    mapping(address=>uint[]) givenLoans;
    mapping(address=>uint[]) myLoans;

    event loanTermsRegistered(address borrower,uint loanAmount,uint timePeriod);
    event loanAgreementMade(address lender,uint loanNumber);
    event loanRepaid(uint loanNumber);
    event issueRaised(address lender,uint loanNumber);

    //default rate of interest is taken as 12% of the loan amount;

// function to register a loan request by the borrower
    function registerLoanTerms(address _borrower,uint _loanAmount,uint _timePeriod) public{
        require(msg.sender==_borrower,"Only borrower can create a loan request");
        require(_loanAmount>0,"loan amount must be greater than 0");
        loanTerms memory l=loanTerms(address(0),_borrower,block.timestamp,_loanAmount,_timePeriod,false);
        emit loanTermsRegistered(_borrower,_loanAmount,_timePeriod);
        myLoans[msg.sender].push(loanNumber);
        loanList[loanNumber++]=l;
    }

// function to agree for a loan by the lender 
    function loanAgreement(uint _loanNumber) public payable{
        require(loanList[_loanNumber].lender==address(0),"Sorry this loan is approved by some other lender");
        require(msg.value==loanList[_loanNumber].loanAmount,"Please pay the exact loan amount");
        payable(loanList[_loanNumber].borrower).transfer(loanList[_loanNumber].loanAmount);
        loanList[_loanNumber].lender=msg.sender;
        givenLoans[msg.sender].push(_loanNumber);
        emit loanAgreementMade(msg.sender,_loanNumber);
    }

// function for the borrower to repay the loan  
    function repayLoan(uint _loanNumber) public payable{
        require(msg.sender==loanList[_loanNumber].borrower,"Sorry you are not the borrower for this loan");
        require(loanList[_loanNumber].loanPaid==false,"Sorry loan is already paid back");
        // require(msg.value==(12*loanList[_loanNumber].loanAmount)/100 + loanList[_loanNumber].loanAmount,"Please pay the exact loan amount after the interest");
        payable(loanList[_loanNumber].lender).transfer(msg.value);
        loanList[_loanNumber].loanPaid=true;
        emit loanRepaid(_loanNumber);  
    }

// to raise an issue if loan is not paid by borrower on time and legal actions will be taken automatically using frontend 
    function raiseIssue(uint _loanNumber) public{
        require(msg.sender==loanList[_loanNumber].lender,"Sorry you are not the lender for this loan");
        require(loanList[_loanNumber].loanPaid==false,"Sorry this loan is paid, You cant raise an issue");
        // require(block.timestamp>loanList[_loanNumber].lendingDate + (loanList[_loanNumber].timePeriod*365 days),"You cant raise an issue before the due date");
        emit issueRaised(msg.sender,_loanNumber);
    }


// get the loans I have created a request for 
    function getMyLoans() public view returns(uint[] memory){
        return myLoans[msg.sender];
    }

// list of loans given by the lenders 
    function getMyGivenLoans() public view returns(uint[] memory){
        return givenLoans[msg.sender];
    }

}