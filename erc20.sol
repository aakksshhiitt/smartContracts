// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

abstract contract erc20Token{

    function name() public view virtual returns(string memory);
    function symbol() public view virtual returns(string memory);
    function decimal() public view virtual returns(uint8);

    function totalSupply() public view virtual returns(uint256);
    function balanceOf(address _owner) public view virtual returns(uint256);
    function transfer(address _to,uint _value) public virtual returns(bool success);
    function transferFrom(address _from,address _to,uint _value) public virtual returns(bool success);
    function approve(address _spender,uint _value) public virtual returns(bool success);
    function allowance(address _owner,address _spender) public view virtual returns(uint256);

    event Transfer(address indexed _from,address indexed _to,uint _value);
    event Approval(address indexed _owner,address indexed _spender,uint _value);
}

contract ownership{
    address public owner;
    address public newOwner;
    event changeOwner(address indexed _from,address indexed _to);

    constructor(){
        owner=msg.sender;
        newOwner=address(0);
    }

    function changeOwnership(address _to) public{
        require(msg.sender==owner,"Only owner can change the ownership");
        newOwner=_to;
    }

    function acceptOwnership() public{
        require(msg.sender==newOwner,"Only new owner can accept the ownerhip request");
        emit changeOwner(owner,newOwner);
        owner=newOwner;
        newOwner=address(0);
    }
}

contract myERC20Token is erc20Token,ownership{

    string _name;
    string _symbol;
    uint8 _decimal;
    uint256 _totalSupply;
    address public minter;
    mapping(address=>uint) tokenBalance;
    mapping(address=>mapping(address=>uint)) allowed;

    constructor(string memory name_,string memory symbol_,uint totalSupply_){
        _name=name_;
        _symbol=symbol_;
        _totalSupply=totalSupply_;
        minter=msg.sender;
        tokenBalance[minter]=totalSupply_;
    }


    function name() public view override returns(string memory){
        return _name;
    }

    function symbol() public view override returns(string memory){
        return _symbol;
    }

    function decimal() public pure override returns(uint8){
        return 18;
    }

    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns(uint256){
        return tokenBalance[_owner];
    }

    function transfer(address _to,uint _value) public override returns(bool success){
        require(tokenBalance[msg.sender]>=_value,"Sorry balance is not sufficient");
        tokenBalance[msg.sender]-=_value;
        tokenBalance[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }

    function transferFrom(address _from,address _to,uint _value) public override returns(bool success){
        require(allowed[_from][msg.sender]>=_value,"Sorry you are not allowed to transfer this amount");
        tokenBalance[_from]-=_value;
        tokenBalance[_to]+=_value;
        allowed[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender,uint _value) public override returns(bool success){
        require(tokenBalance[msg.sender]>=_value,"Sorry you don't have sufficient funds");
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function allowance(address _owner,address _spender) public view override returns(uint256){
        return allowed[_owner][_spender];
    }

}