pragma solidity ^0.4.13;

import './token/DatumGenesisToken.sol';
import './math/SafeMath.sol';
import './RefundVault.sol';

/**
 * @title  
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * DatumCrowdSale have a start and end date, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract DatumCrowdSale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  DatumGenesisToken public token;

  // start and end date where investments are allowed (both inclusive)
  uint256 public startDate = 1501156800;
  uint256 public endDate = 1502366400;

  // Minimum amount to participate
  uint256 public minimumParticipationAmount = 1000000000000000000 wei; //1 ether

    // Minimum amount to participate
  uint256 public maximalParticipationAmount = 1000000000000000000000 wei; //1000 ether

  // address where funds are collected
  address wallet;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  // how many token units a buyer gets per wei
  uint256 rate = 1;

  // how is the multiplyer
  uint256 bonusRate = 1;

  // amount of raised money in wei
  uint256 public weiRaised;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

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


    /// @notice Log an event for each funding contributed during the public phase
    /// @notice Events are not logged when the constructor is being executed during
    ///         deployment, so the preallocations will not be logged
    event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);

  function DatumCrowdSale(uint256 _goal, uint256 _startDate, uint256 _endDate, uint256 _rate, address _wallet) {
    token = createTokenContract();
    vault = new RefundVault(_wallet);
    goal = _goal;
    startDate = _startDate;
    endDate = _endDate;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold. 
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (DatumGenesisToken) {
    return new DatumGenesisToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);


    //purchase tokens
    token.transfer(beneficiary, tokens / 10000000000000000);
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


  // should be called after crowdsale ends, to do
  // some extra finalization work
  function finalizeTestSuccess() onlyOwner {
    
    vault.close();

    Finalized();
    
    isFinalized = true;
  }

   function finalizeTestRefund() onlyOwner {
    
    vault.enableRefunds();

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


}
