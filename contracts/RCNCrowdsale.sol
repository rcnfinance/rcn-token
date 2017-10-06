pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./zeppelin/SafeMath.sol";
import "./Crowdsale.sol";
import "./CapWhitelist.sol";
import "./MintableToken.sol";

contract RCNCrowdsale is Crowdsale {
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
    uint256 public constant capPerAddress = 20 * tokenExchangeRate * 10**decimals; // 20 ETH
    uint256 public constant minBuyTokens = 400 * 10**decimals; // 0.1 ETH

    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreateRCN(address indexed _to, uint256 _value);

    mapping (address => uint256) bought; // cap map
    address whitelistContract;

    uint256 public raised;

    MintableToken public token;

    // constructor
    function RCNCrowdsale(address _ethFundDeposit,
          address _rcnFundDeposit,
          uint256 _fundingStartBlock,
          uint256 _fundingEndBlock) {
      token = new MintableToken();
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      rcnFundDeposit = _rcnFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      token.mint(rcnFundDeposit, rcnFund);
      raised = rcnFund;
      whitelistContract = new CapWhitelist();
      CreateRCN(rcnFundDeposit, rcnFund);  // logs Ripio Intl fund
    }

    /// @dev Accepts ether and creates new RCN tokens.
    function createTokens() payable external {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) payable {
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;
      if (beneficiary == 0x0) throw;

      uint256 tokens = msg.value.mul(tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = raised.add(tokens);

      // if sender is not whitelisted and exceeds the cap, cancel the transaction
      if (!CapWhitelist(whitelistContract).whitelist(msg.sender))
        if (bought[msg.sender] + tokens > capPerAddress) throw;

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      // return money if tokens is less than the min amount and the token is not finalizing
      // the min amount does not apply if the availables tokens are less than the min amount.
      if (tokens < minBuyTokens && (tokenCreationCap - raised) > minBuyTokens) throw;

      raised = checkedSupply;
      token.mint(beneficiary, tokens);
      bought[msg.sender] += tokens;
      CreateRCN(beneficiary, tokens);  // logs token creation

      forwardFunds();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
      ethFundDeposit.transfer(msg.value);
    }
}