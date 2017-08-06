pragma solidity ^0.4.13;


/*
    Copyright 2017

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


import "./token/MiniMeToken.sol";
import "./ownership/Ownable.sol";


/**
 * @title DatumGenesisToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator. 
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract DatumGenesisToken is MiniMeToken {

  string public name = "DAT Genesis Token";           //The Token's name: e.g. Dat Genesis Tokens
  uint8 public decimals = 6;                         //Number of decimals of the smallest unit
  string public symbol = "DATG";                             //An identifier: e.g. REP
  string public version = 'DAT_0.1';                //An arbitrary versioning scheme

}