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
 

import './DatumGenesisToken.sol';
import './math/SafeMath.sol';
import './RefundVault.sol';

/**
 * @title  
 * @dev DatCrowdSale is a contract for managing a token crowdsale.
 * DatCrowdSale have a start and end date, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a refundable valut 
 * as they arrive.
 */
contract DatCrowdSale is TokenController, Ownable {
  using SafeMath for uint256;

  // The token being sold
  DatumGenesisToken public token;

  // start and end date where investments are allowed (both inclusive)
  uint256 public startDate = 1501156800;
  uint256 public endDate = 1502366400;

  // Minimum amount to participate
  uint256 public minimumParticipationAmount = 1000000000000000000 wei; //1 ether

  // Maximum amount to participate
  uint256 public maximalParticipationAmount = 1000000000000000000000 wei; //1000 ether

  // address where funds are collected
  address wallet;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  // how many token units a buyer gets per ether
  uint256 rate = 15000;

  // amount of raised money in wei
  uint256 public weiRaised;

  // minimum amount of funds to be raised in weis
  uint256 public goal = 5000000000000000000000 wei;

  //the token used for this crowd sale
  DatumGenesisToken public tokenContract;   // The new token for this Campaign

  //flag for final of crowdsale
  bool public isFinalized = false;


  event Finalized();

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  /**
  * @notice Log an event for each funding contributed during the public phase
  * @notice Events are not logged when the constructor is being executed during
  *         deployment, so the preallocations will not be logged
  */
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


  
  function DatCrowdSale(uint256 _goal, uint256 _startDate, uint256 _endDate, uint256 _rate, address _tokenAddress, address _wallet) {
    vault = new RefundVault(_wallet);
    goal = _goal;
    startDate = _startDate;
    endDate = _endDate;
    rate = _rate;
    tokenContract = DatumGenesisToken(_tokenAddress);
    wallet = _wallet;
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) internal {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    //purchase tokens
    //token.transfer(beneficiary, tokens / 10000000000000000);
    tokenContract.generateTokens(beneficiary, tokens / 10000000000000000);


    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // Log an event of the participant's contribution
    LogParticipation(msg.sender, weiAmount, now);

    //forward funds to wallet
    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() {
    require(isFinalized);
    require(!goalReached());
    vault.refund(msg.sender);
  }

  // should be called after crowdsale ends, to do
  // some extra finalization work
  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();
    
    isFinalized = true;
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

  // @return true if the goal is reached
  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = startDate <= now && endDate >= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    return withinPeriod && nonZeroPurchase && minAmount;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endDate;
  }

  /////////////////
// TokenController interface
/////////////////

/// @notice `proxyPayment()` allows the caller to send ether to the sale and
/// have the tokens created in an address of their choosing
/// @param _owner The address that will hold the newly created tokens

    function proxyPayment(address _owner) payable returns(bool) {
        buyTokens(_owner);
        return true;
    }

/// @notice Notifies the controller about a transfer, for this crowdsale all
///  transfers are allowed by default and no extra notifications are needed
/// @param _from The origin of the transfer
/// @param _to The destination of the transfer
/// @param _amount The amount of the transfer
/// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool) {
        return true;
    }

/// @notice Notifies the controller about an approval, for this crowdsale all
///  approvals are allowed by default and no extra notifications are needed
/// @param _owner The address that calls `approve()`
/// @param _spender The spender in the `approve()` call
/// @param _amount The amount in the `approve()` call
/// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool)
    {
        return true;
    }
}

