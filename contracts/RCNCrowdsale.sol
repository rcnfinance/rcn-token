pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./zeppelin/SafeMath.sol";
import "./Crowdsale.sol";
import "./CapWhitelist.sol";
import "./RCNToken.sol";

contract RCNCrowdsale is Crowdsale {
    using SafeMath for uint256;

    // metadata
    uint256 public constant decimals = 18;

    // contracts
    address public ethFundDeposit;      // deposit address for ETH for Ripio
    address public rcnFundDeposit;      // deposit address for Ripio use and RCN User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartTimestamp;
    uint256 public fundingEndTimestamp;
    uint256 public constant rcnFund = 490 * (10**6) * 10**decimals;   // 490m RCN reserved for Ripio use
    uint256 public constant tokenExchangeRate = 4000; // 4000 RCN tokens per 1 ETH
    uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;
    uint256 public constant minBuyTokens = 400 * 10**decimals; // 0.1 ETH

    // events
    event CreateRCN(address indexed _to, uint256 _value);

    mapping (address => uint256) bought; // cap map

    CapWhitelist public whiteList;
    RCNToken public token;

    // constructor
    function RCNCrowdsale(address _ethFundDeposit,
          address _rcnFundDeposit,
          uint256 _fundingStartTimestamp,
          uint256 _fundingEndTimestamp) {
      token = new RCNToken();
      whiteList = new CapWhitelist();

      // sanity checks
      assert(_ethFundDeposit != 0x0);
      assert(_rcnFundDeposit != 0x0);
      assert(_fundingStartTimestamp < _fundingEndTimestamp);
      assert(uint256(token.decimals()) == decimals); 

      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      rcnFundDeposit = _rcnFundDeposit;
      fundingStartTimestamp = _fundingStartTimestamp;
      fundingEndTimestamp = _fundingEndTimestamp;
      token.mint(rcnFundDeposit, rcnFund);
      CreateRCN(rcnFundDeposit, rcnFund);  // logs Ripio Intl fund
    }

    /// @dev Accepts ether and creates new RCN tokens.
    function createTokens() payable external {
      buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) payable {
      require (!isFinalized);
      require (block.timestamp >= fundingStartTimestamp);
      require (block.timestamp <= fundingEndTimestamp);
      require (msg.value != 0);
      require (beneficiary != 0x0);

      uint256 tokens = msg.value.mul(tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = token.totalSupply().add(tokens);
      uint256 checkedBought = bought[msg.sender].add(tokens);

      // if sender is not whitelisted and exceeds the cap, cancel the transaction
      require (checkedBought <= whiteList.whitelist(msg.sender));

      // return money if something goes wrong
      require (tokenCreationCap >= checkedSupply);

      // return money if tokens is less than the min amount and the token is not finalizing
      // the min amount does not apply if the availables tokens are less than the min amount.
      require (tokens >= minBuyTokens || (tokenCreationCap - token.totalSupply()) <= minBuyTokens);

      token.mint(beneficiary, tokens);
      bought[msg.sender] = checkedBought;
      CreateRCN(beneficiary, tokens);  // logs token creation

      forwardFunds();
    }

    function finalize() {
      require (!isFinalized);
      require (block.timestamp > fundingEndTimestamp || token.totalSupply() == tokenCreationCap);
      require (msg.sender == ethFundDeposit);
      isFinalized = true;
      token.finishMinting();
      whiteList.destruct();
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
      ethFundDeposit.transfer(msg.value);
    }

    function setWhitelist(address _address, uint256 _amount) {
      require (msg.sender == ethFundDeposit);
      whiteList.setWhitelisted(_address, _amount);
    }
}