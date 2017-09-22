pragma solidity ^0.4.11;

import './Crowdsale.sol';

import './zeppelin/Ownable.sol';
import './zeppelin/SafeMath.sol';
import './zeppelin/Math.sol';

contract Preallocation is Ownable {
    using SafeMath for uint;

    address public investor;
    uint public maxBalance;

    enum States { Pending, Success, Fail }
    States public state = States.Pending;

    event InvestorChanged(address from, address to);

    event FundsLoaded(uint value, address from);
    event FundsRefunded(uint balance);

    event InvestmentSucceeded(uint value);
    event InvestmentFailed();


    function Preallocation(address _investor, uint _maxBalance) {
        investor = _investor;
        maxBalance = _maxBalance;
    }

    function () payable {
        if (this.balance > maxBalance) {
          throw;
        }
        FundsLoaded(msg.value, msg.sender);
    }

    function withdraw() onlyOwner notState(States.Success) {
        uint bal = this.balance;
        if (!investor.send(bal)) {
            throw;
        }

        FundsRefunded(bal);
    }

    function setInvestor(address _investor) onlyOwner {
        InvestorChanged(investor, _investor);
        investor = _investor;
    }

    function buyTokens(Crowdsale crowdsale) onlyOwner {
        uint bal = Math.min256(this.balance, maxBalance);
        crowdsale.buyTokens.value(bal)(investor);

        state = States.Success;
        InvestmentSucceeded(bal);
    }

    function setFailed() onlyOwner {
      state = States.Fail;
      InvestmentFailed();
    }

    function stateIs(States _state) constant returns (bool) {
        return state == _state;
    }

    modifier onlyState(States _state) {
        require (state == _state);
        _;
    }

    modifier notState(States _state) {
        require (state != _state);
        _;
    }
}
