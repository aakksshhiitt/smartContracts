// SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SoulBoundToken is ERC721, Ownable, ERC721URIStorage{

    // state variables

    address public admin;    // current admin
    address newAdmin; // address of the new admin that is proposed by the current admin

    struct SBT{                       
        uint256 uinqueId;
        address ownerAddress;
        string name;
        string metadata;
    }

    mapping(uint256=>SBT) SBTList;     // mapping to list all the SBTs
    mapping(address=>uint256[]) myHoldings;    // mapping shows the list of token IDs own by the particular address

    constructor(address _admin) ERC721("soulBoundToken", "SBT") Ownable(_admin){
        admin=_admin;
        newAdmin=address(0);
    }

    event SBTMinted(address indexed _to, uint256 indexed _tokenId);
    event SBTRevoked(uint256 indexed _tokenId);
    event newAdminSet(address indexed admin,address indexed newAdmin);


// modifier for only owner access
    modifier onlyAdmin{
        require(msg.sender==admin,"Only admin can access this functionality");
        _;
    }

// function for the current admin to request for the admin change
    function changeAdmin(address _newAdmin) public onlyAdmin{
        require(_newAdmin!=address(0),"Please provide a valid admin address");
        newAdmin=_newAdmin;
    }

// function for the new admin to accept the admin request and be the new admin   
    function acceptAdminRequest() public{
        require(msg.sender==newAdmin,"Only the new admin can accept the request");
        admin=newAdmin;
        newAdmin=address(0);
        emit newAdminSet(admin,newAdmin);
    }

// function overriden to return the token uri for particular tokenId
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return SBTList[_tokenId].metadata;
    }

// function overriden to pause the approval
    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert("Approval not allowed as the token can't be trnaferred");
    }

// function overriden to pause the transfer of SBT
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721){
        revert("We can't transfer the soulBoundTokens, as it only belongs to specific user");
    }

// function overrides the transfer ownership and put pause on owner transfer;
    function transferOwnership(address newOwner) public override onlyAdmin {
        revert("We can't transfer the ownership and soulBoundTokens, as it only belongs to specific user");
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {
        revert("Approval not allowed as the token can't be trnaferred");
    }

// function for the Admin to mint the SBT to a particular user;
    function mintSBT(address to, string memory name, uint256 _tokenId, string memory metadata) public onlyAdmin {
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, metadata);
        SBT memory s=SBT(_tokenId, to, name, metadata);
        SBTList[_tokenId]=s;
        myHoldings[to].push(_tokenId);

        emit SBTMinted(to, _tokenId);
        
    }

// function used by the admin only to revoke a particular SBT
    function revokeSBT(uint256 _tokenId) public onlyAdmin{
        _burn(_tokenId);
        emit SBTRevoked(_tokenId);
    }

// function to return the SBT details;
    function getSBTDetails(uint256 tokenId) public view returns(SBT memory){
        require(SBTList[tokenId].ownerAddress!=address(0),"This token id doesnot exist");
        return SBTList[tokenId];
    }



    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
