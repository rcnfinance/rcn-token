pragma solidity ^0.4.11;

contract CapWhitelist {
    address public owner;
    mapping (address => bool) public whitelist;

    function CapWhitelist() {
        owner = msg.sender;
        // Replace in prod
        whitelist[address(0xeab987dc90b29b9c0ec4863463697907e7ce1d55)] = true;
    }

    function destruct() {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}