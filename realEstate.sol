// SPDX-License-Identifier:MIT
pragma solidity^0.8.28;

contract realEstate{

// declaring state functions
    struct Property{
        uint propertyId;
        address owner;
        string name;
        string description;
        uint256 price;
        string location;
        bool forSale;
    }
    uint256 propertyId;
    constructor(){
        propertyId=1;
    }
    mapping(uint256=>Property) propertyList;

// declaring events
    event PropertyRegistered(uint256 indexed propertyId,address indexed  owner,uint256 indexed price);
    event PropertyBought(uint256 indexed _propertyId,address indexed previousOwner,address indexed owner);
    event PropertyPriceChanged(uint256 indexed _propertyId,uint256 indexed newPrice);
    event PropertyDonated(address indexed onwer,address indexed _to);
    event PropertyMarkedForSale(uint256 indexed _propertyId);
    event PropertyRemovedfromSale(uint256 indexed _propertyId);

// function for the owenr to list their property 
    function listProperty(string memory _name, string memory _description, uint256 _price, string memory _location) public{
        require(_price>0,"Please provide a valid price");
        Property memory p=Property(propertyId, msg.sender, _name, _description, _price, _location, false);
        propertyList[propertyId++]=p;
        emit PropertyRegistered(propertyId-1, msg.sender, _price);
    }

// function for the owner to mark their property for sale
    function markForSale(uint256 _propertyId) public{
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        require(msg.sender==propertyList[_propertyId].owner,"Only owner can mark it's property for sale");
        require(propertyList[_propertyId].forSale==false,"Property is already on sale");
        propertyList[_propertyId].forSale=true;
        emit PropertyMarkedForSale(_propertyId);
    }

// function for the owner to remove the property from sale
    function removeFromSale(uint256 _propertyId) public{
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        require(msg.sender==propertyList[_propertyId].owner,"Only owner can remove this property from sale");
        require(propertyList[_propertyId].forSale==true,"Property is already not on sale");
        propertyList[_propertyId].forSale=false;
        emit PropertyMarkedForSale(_propertyId);
    }

// function to check the property details using proeprtyId
    function showPropertyDetails(uint256 _propertyId) public view returns(Property memory){
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        return propertyList[_propertyId];
    }

// function for the buyers to buy the property and pay for the exact price
    function buyProperty(uint256 _propertyId) public payable{
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        require(msg.sender!=propertyList[_propertyId].owner,"You are already the owner of the property");
        require(propertyList[_propertyId].forSale==true,"Sorry the proeprty is not marked for sale yet");
        require(msg.value==propertyList[_propertyId].price,"Please pay the exact amount to purchase the property");
        address previousOwner=propertyList[_propertyId].owner;
        propertyList[_propertyId].owner=msg.sender;
        payable(previousOwner).transfer(propertyList[_propertyId].price);

        emit PropertyBought(_propertyId, previousOwner, msg.sender);
    }

// function for the owner to change the price of the property
    function changePropertyPrice(uint256 _propertyId, uint256 _newPrice) public{
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        require(msg.sender==propertyList[_propertyId].owner,"Only owner can change the price of the property");
        propertyList[_propertyId].price=_newPrice;

        emit PropertyPriceChanged(_propertyId, _newPrice);
    }

// function for the owner to donate the property to another address
    function donateProperty(uint256 _propertyId, address _to) public{
        require(_propertyId>0 && _propertyId<propertyId,"Please provide a valid propertyId");
        require(msg.sender==propertyList[_propertyId].owner,"Only owner can donate the property");
        emit PropertyDonated(msg.sender, _to);
        propertyList[_propertyId].owner=_to;
    }
}