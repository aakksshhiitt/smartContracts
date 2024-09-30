// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

contract bloodDonation{

// declaring variables
    address manager;
    struct Member{
        string name;
        string aadhar;
        uint8 age;
        string contactNumber;
        string homeAddress;
        string bloodGroup;
        uint256 bloodDonated;
        uint256 bloodReceived;
    }

    constructor(){
        manager=msg.sender;
    }

    mapping(string=>Member) memberList;
    mapping(string=>uint256) bloodLeft;
    event bloodDonated(string indexed _aadhar,uint indexed _bottlesCount);
    event bloodReceived(string indexed _aadhar,uint indexed _bottlesCount);
    event memberRegistered(string indexed _aadhar,string indexed _bloodGroup);

// Function to register new member
    function registerMember(string memory _name, string memory _aadhar, uint8 _age, string memory _contactNumber, string memory _homeAddress, string memory _bloodGroup) public{
        require(msg.sender==manager,"Only manager can registe the Donor's");
        require(_age>0,"Sorry, age can't be 0");
        require(memberList[_aadhar].age==0,"Sorry the donor is alreadyRegistered");
        Member memory d=Member(_name,_aadhar,_age,_contactNumber,_homeAddress,_bloodGroup,0,0);
        memberList[_aadhar]=d;
        
        emit memberRegistered(_aadhar,_bloodGroup);
    }

// function that returns the availability of a particular blood type
    function checkBloodAvailability(string memory _bloodGroup) public view returns(uint256){
        return bloodLeft[_bloodGroup];
    }

// get Member realted details using aadhar card
    function getMemeberDetails(string memory _aadhar) public view returns(Member memory){
        return memberList[_aadhar];
    }

// function used to donate the blood and update the variables for taht.
    function donateBlood(string memory _aadhar, uint256 _bottleCount) public{
        require(msg.sender==manager,"Only manager can update the blood donation details");
        require(_bottleCount>0,"Donation bottle count can't be 0");
        require(memberList[_aadhar].age!=0,"Please register the member first");
        memberList[_aadhar].bloodDonated+=_bottleCount;
        bloodLeft[memberList[_aadhar].bloodGroup]+=_bottleCount;
        emit bloodDonated(_aadhar,_bottleCount);
    }

// function used to receive the blood by any registered member.
    function getBlood(string memory _aadhar, uint256 _bottleCount) public{
        require(msg.sender==manager,"Only manager can update the blood donation details");
        require(memberList[_aadhar].age!=0,"Please register the member first");
        require(_bottleCount>0 && _bottleCount<=bloodLeft[memberList[_aadhar].bloodGroup],"Sorry Less amount of blood is left");
        memberList[_aadhar].bloodReceived+=_bottleCount;
        bloodLeft[memberList[_aadhar].bloodGroup]-=_bottleCount;
        emit bloodReceived(_aadhar,_bottleCount);
    }
}