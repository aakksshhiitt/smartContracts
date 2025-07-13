// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTCertificate is ERC721, Ownable, ERC721URIStorage{

// declaring the state variables
    using Strings for uint256;
    struct NFT{
        uint256 tokenId;
        address owner;
        string name;
        string tokenURI;
        string courseName;
        string issueDate;
        address issuerAddress;
        uint256 issueTime;
    }
    struct Issuer{
        address issuerAddress;
        string name;
        string organization;
    }
    uint256 public tokenId; 
    uint256 expiryDate; // represents the unique token id for different NFT
    mapping(uint256 => NFT) NFTDetails;  //stores the details of NFT certificate for each token id
    mapping(uint256 => uint256) totalRating;
    mapping(uint256=>uint256) totalUserRated;
    mapping(address=>mapping(uint256=>bool)) hasRated;
    mapping(uint256=>bool) public alreadyRevoked;
    mapping(address=>Issuer) public issuerProfile;


    constructor() ERC721("MYNFT","MN") Ownable(msg.sender){
        tokenId=0;
        expiryDate=90 days;
    }

    event NFTMinted(uint256 indexed tokenId, address indexed issuer, uint256 indexed time);
    event Revoked(uint256 indexed tokenId, uint256 indexed time);
    event UnRevoked(uint256 indexed tokenId, uint256 indexed time);
    event IssuerAdded(address indexed issuer, uint256 indexed time);

// functionto mint the NFT Certificate, set the token URI for the same and store the NFT details as well.
    function mintMyNFT(address _receipentAddress, string memory _name, string memory _tokenURI, string memory _courseName, string memory _issueDate) public{
        require(issuerProfile[msg.sender].issuerAddress!=address(0),"You need to get the issuer role to issue the Certificate");
        tokenId++;
        _safeMint(_receipentAddress, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        NFT memory n= NFT(tokenId, _receipentAddress, _name, _tokenURI, _courseName, _issueDate, msg.sender,block.timestamp);
        NFTDetails[tokenId]=n;
        emit NFTMinted(tokenId, msg.sender, block.timestamp);
    }

// function to fetch the details of the NFT Certificate for a particular tokenId.

    function registerIssuer(address _issuerAddress, string memory _name, string memory _companyName) public{
        require(issuerProfile[_issuerAddress].issuerAddress==address(0),"You are already registered as an issuer");
        Issuer memory i=Issuer(_issuerAddress,_name, _companyName);
        issuerProfile[_issuerAddress]=i;
        emit IssuerAdded(_issuerAddress, block.timestamp);
    }
    
    function getNFTDetails(uint256 _tokenId) public view returns(NFT memory){
        require(alreadyRevoked[_tokenId]==false,"This certificate has been revoked");
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        return NFTDetails[_tokenId];
    }

    function rateCertificate(uint256 _tokenId, uint256 _rating) public{
        require(alreadyRevoked[_tokenId]==false,"This certificate has been revoked");
        require(_rating>0 && _rating<=5,"Please provide a rating between 1 to 5");
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        require(hasRated[msg.sender][_tokenId]==false,"You have already rated for this Certificate");
        // require(the certificate has not been revoked
        totalRating[_tokenId]+=_rating*10**18;
        totalUserRated[_tokenId]++;
        hasRated[msg.sender][_tokenId]=true;
        // emit ratingCompleted
    }

    function getRating(uint256 _tokenId) public view returns(uint256){
        require(alreadyRevoked[_tokenId]==false,"This certificate has been revoked");
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        require(totalRating[_tokenId]>0,"Sorry no rating to this token has been made");
        return totalRating[_tokenId]/totalUserRated[_tokenId];
    }

    function revokeCertificate(uint256 _tokenId) public{
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        require(alreadyRevoked[_tokenId]==true,"This certificate has been already revoked");
        alreadyRevoked[_tokenId]=true;
        emit Revoked(_tokenId, block.timestamp);
    }

    function removeRevoke(uint256 _tokenId) public{
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        require(alreadyRevoked[_tokenId]==false,"This certificate is already not revoked");
        alreadyRevoked[_tokenId]=false;
        emit UnRevoked(_tokenId, block.timestamp);
    }

    function expiryTime(uint256 _tokenId) public view returns(uint256){
        require(_tokenId>0 && _tokenId<=tokenId,"Please provide a valid tokenId");
        return NFTDetails[_tokenId].issueTime+expiryDate;
    }

    
    // function overriden to pause the approval
    function approve(address _to, uint256 _tokenId) public pure override(ERC721, IERC721) {
        revert("Approval not allowed as the token can't be trnaferred");
    }

// function overriden to pause the transfer of Certificate
    function transferFrom(address _from, address _to, uint256 _tokenId) public pure override(ERC721, IERC721){
        revert("We can't transfer the soulBoundTokens, as it only belongs to specific user");
    }

// function overrides the transfer ownership and put pause on owner transfer;
    function transferOwnership(address _newOwner) public pure override {
        revert("We can't transfer the ownership and soulBoundTokens, as it only belongs to specific user");
    }

    function setApprovalForAll(address operator, bool approved) public pure override(ERC721, IERC721) {
        revert("Approval not allowed as the token can't be trnaferred");
    }

    


    // +++++++++++++++++ overriden functions ++++++++++++++++++ //

    function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721URIStorage) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721,ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
     


}