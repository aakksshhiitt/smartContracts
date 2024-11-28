// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Creating the token to transfer in exchange of USD
contract Token is ERC20{
    constructor(uint256 _value) ERC20("MyToken","MT"){
        _mint(msg.sender,_value);
    }
}
