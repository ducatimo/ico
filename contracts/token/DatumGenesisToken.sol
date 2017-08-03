pragma solidity ^0.4.13;


import "./StandardToken.sol";
import "../ownership/Ownable.sol";


/**
 * @title DatumGenesisToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract DatumGenesisToken is StandardToken, Ownable {

  string public constant name = "DAT (Genesis)";
  string public constant symbol = "DATG";
  uint256 public constant decimals = 2;

  uint256 public constant INITIAL_SUPPLY = 75000000;

  /**
   * @dev Contructor that gives msg.sender all of existing tokens. 
   */
  function DatumGenesisToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}