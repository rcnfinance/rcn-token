var RCNToken = artifacts.require("./rcn/RCNToken.sol");

function rcnToWei(value){
    return value * 10**18;
}

contract('RCNToken', function(accounts) {
    var instanceRcn;
    it("Create and send tokens", function(){
        return RCNToken.new(accounts[0], accounts[0], 0, 1170000).then(function(instance){
            instanceRcn = instance;
            return instanceRcn.createTokens({from: accounts[1], value: web3.toWei('1', 'ether')});   
        }).then(function(){
            return instanceRcn.balanceOf(accounts[1]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(4000), "Account 1 should have 4000 RCN");
            return instanceRcn.transfer(accounts[2], rcnToWei(1000), { from: accounts[1] });
        }).then(function(){
            return instanceRcn.balanceOf(accounts[1]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(3000), "Account 1 should have 1000 RCN less");
            return instanceRcn.balanceOf(accounts[2]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(1000), "Account 2 should have 1000 RCN");
        });
    });
});