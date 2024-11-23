// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract myNFT is ERC721URIStorage, Ownable{
    constructor() ERC721("MyNFT","MN"){}

    function mint(address _to, uint256 _tokenId, string calldata _uri) public onlyOwner{
        _mint(_to,_tokenId);
        _setTokenURI(_tokenId,_uri);
    }
}

//  uri link for ape.json metadata from nft.storage
// ipfs://bafkreiefdwzpumkdkrkv4ldl53ffq34u2hgk2s45o4kt2fec3pvreko42i