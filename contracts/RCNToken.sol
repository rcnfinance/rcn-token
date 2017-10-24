pragma solidity ^0.4.11;

import "./MintableToken.sol";

contract RCNToken is MintableToken {
    string public constant name = "Ripio Credit Network Token";
    string public constant symbol = "RCN";
    uint8 public constant decimals = 18;
    string public version = "1.0";
}