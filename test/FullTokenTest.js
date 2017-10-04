var RCNToken = artifacts.require("./rcn/RCNToken.sol");

function rcnToWei(value){
    return value * 10**18;
}

contract('RCNToken', function(accounts) {
    var instanceRcn;
    var initialBalanceAccount2;
    it("Create and finalize crowdsale", function(){
        return RCNToken.new(accounts[2], accounts[3], web3.eth.blockNumber, web3.eth.blockNumber + 100).then(function(instance){
            instanceRcn = instance;
            initialBalanceAccount2 = web3.eth.getBalance(accounts[2]);
            assert.isAbove(web3.eth.getBalance(accounts[1]).toNumber(), web3.toWei('127500', 'ether'), "Account 1 should have more balance");
            return instanceRcn.createTokens({from: accounts[1], value: web3.toWei('127500', 'ether')});   
        }).then(function(){
            return instanceRcn.balanceOf(accounts[1]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(127500 * 4000), "Account 1 should have 510.000.000 RCN");
            return instanceRcn.finalize({ from: accounts[2] });
        }).then(function(){
            return instanceRcn.isFinalized();
        }).then(function(finalized){
            assert.equal(finalized, true, "Token should be finalized");
            assert.isAbove(web3.eth.getBalance(accounts[2]).toNumber() - initialBalanceAccount2.toNumber(),
             web3.toWei('127450', 'ether'), "Account 2 should have all the funding eth")
        });
    });
});
