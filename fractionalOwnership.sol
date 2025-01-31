// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract fractionalOwnership{

// variables declaration
    address manager;
    struct Asset{
        string name;
        string description;
        uint256 totalPrice;
        uint256 totalFraction;
        uint256 pricePerFraction;
        uint256 fractionLeft;
        bool sold;
    }
    uint256 assetNumber;
    mapping(uint256=>Asset) assetList;
    mapping(uint=>address[]) ownersOf;
    mapping(address=>uint256[]) assetsOf;
    mapping(address=>mapping(uint256=>uint256)) fractionHolding;

// modifier
    modifier onlyManager{
        require(msg.sender==manager,"Only manager can access this functionality");
        _;
    }

// constructor
    constructor(){
        assetNumber=1;
        manager=msg.sender;
    }
// event declaration
    event assetRegistered(uint256 indexed _assetNumber);
    event assetBought(uint256 indexed _assetNumber, uint256 indexed _fractionBought);
    event sold(address indexed seller, uint256 indexed _assetNumber);

// function for manager to list the new asset
    function listAsset(string memory _name, string memory _description, uint256 _totalPrice, uint256 _totalFraction) public onlyManager{
        Asset memory a=Asset(_name, _description, _totalPrice, _totalFraction, _totalPrice/_totalFraction, _totalFraction, false);
        assetList[assetNumber++]=a;
        emit assetRegistered(assetNumber-1);
    }

// function to check the asset details
    function checkAssetDetails(uint256 _assetNumber) public view returns(Asset memory){
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number"); 
        return assetList[_assetNumber];
    }

// to check the price of single fraction of particular asset
    function checkFractionPrice(uint256 _assetNumber) public view returns(uint256){
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        return assetList[_assetNumber].pricePerFraction;
    }

// function to check number of fractions left for sale
    function checkFractionsLeft(uint256 _assetNumber) public view returns(uint256){
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        return assetList[_assetNumber].fractionLeft;
    }

// function for the users to buy the specific number of fractions of particular asset    
    function buyAssets(uint256 _assetNumber, uint256 _fractionAmount) public payable{
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        require(assetList[_assetNumber].sold==false,"Sorry, the asset is already sold");
        require(assetList[_assetNumber].fractionLeft>=_fractionAmount,"Sorry, less amount of fractions are left, please check the availability.");
        require(msg.value==assetList[_assetNumber].pricePerFraction*_fractionAmount,"Please pay the exact price for the amount of fraction you want to purchase");
        if(fractionHolding[msg.sender][_assetNumber]==0){
            ownersOf[_assetNumber].push(msg.sender);
            assetsOf[msg.sender].push(_assetNumber);
        }
        assetList[_assetNumber].fractionLeft-=_fractionAmount;
        if(assetList[_assetNumber].fractionLeft==0){
            assetList[_assetNumber].sold=true;
        }
        fractionHolding[msg.sender][_assetNumber]+=_fractionAmount;

        emit assetBought(_assetNumber, _fractionAmount);

    }

// check number of assets the user holds for particular asset number 
    function myHoldingsOf(uint256 _assetNumber) public view returns(uint256){
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        return fractionHolding[msg.sender][_assetNumber];
    }

// function for the users to check the asset number he holds.
    function myAssets() public view returns(uint256[] memory){
        return assetsOf[msg.sender];
    }

// function to check all the owners of particular asset
    function showAssetOwners(uint256 _assetNumber) public view returns(address[] memory){
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        return ownersOf[_assetNumber];
    }

// function for the buyers to sellback the particular asset he has bought
    function sellbackAsset(uint256 _assetNumber) public{
        require(_assetNumber>0 && _assetNumber<assetNumber,"Please provide a valid asset number");
        require(fractionHolding[msg.sender][_assetNumber]>0,"Sorry, you do not hold any fraction of this asset");

        uint256 arrayLength=ownersOf[_assetNumber].length;
        for(uint256 i=0;i<arrayLength;i++){
            if(ownersOf[_assetNumber][i]==msg.sender){
                ownersOf[_assetNumber][i]=ownersOf[_assetNumber][arrayLength-1];
                ownersOf[_assetNumber].pop();
                break;
            }
        }
        arrayLength=assetsOf[msg.sender].length;
        for(uint i=0;i<arrayLength;i++){
            if(assetsOf[msg.sender][i]==_assetNumber){
                assetsOf[msg.sender][i]=assetsOf[msg.sender][arrayLength-1];
                assetsOf[msg.sender].pop();
                break;
            }
        }

        if(assetList[_assetNumber].sold==true){
            assetList[_assetNumber].sold=false;
        }
        assetList[_assetNumber].fractionLeft+=fractionHolding[msg.sender][_assetNumber];
        uint256 refundAmount=fractionHolding[msg.sender][_assetNumber]*assetList[_assetNumber].pricePerFraction;
        fractionHolding[msg.sender][_assetNumber]=0;
        
        payable(msg.sender).transfer(refundAmount);

        emit sold(msg.sender, _assetNumber);

    }

}