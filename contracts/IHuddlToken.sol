pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol"; 


contract IHuddlToken is IERC20{

    function mint(address to, uint256 value)external returns (bool);
    
    function decimals() public view returns(uint8);
}