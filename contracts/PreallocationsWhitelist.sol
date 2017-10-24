pragma solidity ^0.4.11;

contract PreallocationsWhitelist {
    address public owner;
    mapping (address => bool) public whitelist;

    event Set(address _address, bool _enabled);

    function PreallocationsWhitelist() {
        owner = msg.sender;
        // Set in prod
    }

    function destruct() {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function setWhitelisted(address _address, bool _enabled) {
        require(msg.sender == owner);
        setWhitelistInternal(_address, _enabled);
    }

    function setWhitelistInternal(address _address, bool _enabled) private {
        whitelist[_address] = _enabled;
        Set(_address, _enabled);
    }
}