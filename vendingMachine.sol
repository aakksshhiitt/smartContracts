// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract vendingMachine{

    address private owner;
    uint256 totalCapacity;   // maximum units of single product
    uint8 sectionsAvailable;  // types of products that can be registered
    uint8 productId;
    struct product{
        string name;
        string description;
        uint256 price;
        uint256 quantityLeft;
    }
    mapping(uint256=>product) productList;

     constructor(uint256 _totalCapacity,uint8 _sectionsAvailable){
        owner=msg.sender;
        totalCapacity=_totalCapacity;
        sectionsAvailable=_sectionsAvailable;
        productId=1;
    }
    
    event productResgitered(string indexed _prodcutName,uint8 indexed _productId);
    event productBought(address indexed _buyer,uint8 indexed _productId,uint256 indexed _quantity);
    event machineRestocked(uint256 indexed _restockTime);
    event ProductDetailsChanged(uint8 indexed productId,string indexed name,uint256 indexed price);

// function to register a new product
    function registerProduct(string memory _name,string memory _description,uint256 _price) public{
        require(msg.sender==owner,"Only owner can register new products");
        require(productId<=sectionsAvailable,"Sorry this machine can't add more item types");
        product memory p=product(_name,_description,_price,totalCapacity);
        emit productResgitered(_name,productId);
        productList[productId++]=p;
    }

// function to buy products by the buyers
    function buyProduct(uint8 _productId,uint256 _quantity) public payable{
        require(msg.sender!=owner,"Owner can't buy its own products");
        require(_productId>0 && _productId<=productId,"Please select a valid productid");
        require(_quantity<=productList[_productId].quantityLeft,"Sorry less number of products are available");
        require(msg.value==productList[_productId].price*_quantity,"Please pay the exact amount to buy specified quantity");
        productList[_productId].quantityLeft-=_quantity;
        emit productBought(msg.sender,_productId,_quantity);
    }

// to restock the vending machine
    function restock() public{
        require(msg.sender==owner,"Only owner can restock the machine");
        require(address(this).balance>0,"Sorry the machine is already full");
        for(uint8 i=1;i<=productId;i++){
            productList[i].quantityLeft=totalCapacity;
        }
        emit machineRestocked(block.timestamp);
        payable(owner).transfer(address(this).balance);
    }

// function to get details of a particular product
    function getProductDetails(uint8 _productId) public view returns(product memory){
        require(_productId<=productId,"Please enter a valid product");
        require(_productId>0 && _productId<=productId,"Please select a valid productid");
        return productList[_productId];
    }

//function used by the owner to change the product and it's details
    function changeItem(uint8 _productId, string memory _name, string memory _description, uint256 _price) public{
        require(msg.sender==owner,"Only owner can change the item details");
        require(_productId>0 && _productId<=productId,"Please select a valid productid");
        require(_price>=0,"Please enter valid price");

        productList[_productId].name=_name;
        productList[_productId].description=_description;
        productList[_productId].price=_price;

        emit ProductDetailsChanged(_productId,_name,_price);
    }
}