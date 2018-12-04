pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol"; 
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/** 
* @dev Mintable Huddl Token
* Initially deployer of the contract is only valid minter. Later on when distribution contract is deployed following steps needs to be followed-:
* 1. Make distribution contract a valid minter
* 2. Renounce miniter role for the token deployer address
* 3. Transfer initial supply tokens to distribution contract address
* 4. At launch of distribution contract transfer tokens to users, contributors and reserve as per monetary policy
*/
contract HuddlToken is ERC20Mintable{

    using SafeMath for uint256;

    string private _name;
    string private _symbol ;
    uint8 private _decimals;

    constructor(
        string name, 
        string symbol, 
        uint8 decimals, 
        uint256 totalSupply
    )
        public 
    {
    
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
        //The initial supply of tokens will be given to the deployer. Deployer will later transfer it to distribution contract
        //At launch distribution contract will give those tokens as per policy to the users, contributors and reserve
        _mint(msg.sender, totalSupply.mul(10 ** uint256(decimals)));
    }

    
    /**
    * @return the name of the token.
    */
    function name() public view returns(string) {
        return _name;
    }

    /**
    * @return the symbol of the token.
    */
    function symbol() public view returns(string) {
        return _symbol;
    }

    /**
    * @return the number of decimals of the token.
    */
    function decimals() public view returns(uint8) {
        return _decimals;
    }

}