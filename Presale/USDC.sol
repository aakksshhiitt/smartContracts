// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract USDC is ERC20{
    constructor() ERC20("USDC","USDC"){
        _mint(msg.sender,1000000000);
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
