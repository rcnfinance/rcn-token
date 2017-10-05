pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./zeppelin/SafeMath.sol";
import "./Crowdsale.sol";
import "./CapWhitelist.sol";

contract RCNToken is StandardToken, Crowdsale {
    using SafeMath for uint256;

    // metadata
    string public constant name = "Ripio Credit Network Token";
    string public constant symbol = "RCN";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Ripio
    address public rcnFundDeposit;      // deposit address for Ripio use and RCN User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant rcnFund = 490 * (10**6) * 10**decimals;   // 490m RCN reserved for Ripio use
    uint256 public constant tokenExchangeRate = 4000; // 4000 RCN tokens per 1 ETH
    uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  690 * (10**6) * 10**decimals;
    uint256 public constant capPerAddress = 20 * tokenExchangeRate * 10**decimals; // 20 ETH
    uint256 public constant minBuyTokens = 400 * 10**decimals; // 0.1 ETH

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateRCN(address indexed _to, uint256 _value);

    mapping (address => uint256) bought; // cap map
    address whitelistContract;

    // constructor
    function RCNToken(address _ethFundDeposit,
          address _rcnFundDeposit,
          uint256 _fundingStartBlock,
          uint256 _fundingEndBlock) {
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      rcnFundDeposit = _rcnFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = rcnFund;
      balances[rcnFundDeposit] = rcnFund;    // Deposit Ripio Intl share
      whitelistContract = new CapWhitelist();
      CreateRCN(rcnFundDeposit, rcnFund);  // logs Ripio Intl fund
    }

    /// @dev Accepts ether and creates new RCN tokens.
    function createTokens() payable external {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) payable {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;
      if (beneficiary == 0x0) throw;

      uint256 tokens = msg.value.mul(tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = totalSupply.add(tokens);

      // if sender is not whitelisted and exceeds the cap, cancel the transaction
      if (!CapWhitelist(whitelistContract).whitelist(msg.sender))
        if (bought[msg.sender] + tokens > capPerAddress) throw;

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      // return money if tokens is less than the min amount and the token is not finalizing
      // the min amount does not apply if the availables tokens are less than the min amount.
      if (tokens < minBuyTokens && (tokenCreationCap - totalSupply) > minBuyTokens) throw;

      totalSupply = checkedSupply;
      balances[beneficiary] += tokens;  // safeAdd not needed; bad semantics to use here
      bought[msg.sender] += tokens;
      CreateRCN(beneficiary, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if (totalSupply < tokenCreationMin) throw;      // have to sell minimum to move to operational
      if (block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      // move to operational
      isFinalized = true;
      if (!ethFundDeposit.send(this.balance)) throw;  // send the eth to Ripio International
      // destroy the whitelist contract
      CapWhitelist(whitelistContract).destruct();
    }

    /// @dev Allows contributors to recover their ether in the case of a failed funding campaign.
    function refund() external {
      if(isFinalized) throw;                       // prevents refund if operational
      if (block.number <= fundingEndBlock) throw; // prevents refund until sale period is over
      if(totalSupply >= tokenCreationMin) throw;  // no refunds if we sold enough
      if(msg.sender == rcnFundDeposit) throw;    // Ripio Intl not entitled to a refund
      uint256 rcnVal = balances[msg.sender];
      if (rcnVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply = totalSupply.sub(rcnVal); // extra safe
      uint256 ethVal = rcnVal / tokenExchangeRate;     // should be safe; previous throws covers edges
      LogRefund(msg.sender, ethVal);               // log it 
      if (!msg.sender.send(ethVal)) throw;       // if you're using a contract; make sure it works with .send gas limits
    }
}