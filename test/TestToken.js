var RCNCrowdsale = artifacts.require("./rcn/RCNCrowdsale.sol");
var StandardToken = artifacts.require("./rcn/StandardToken.sol");

function rcnToWei(value){
    return value * Math.pow(10, 18);
}

contract('RCNCrowdsale', function(accounts) {
    it("Create and send tokens", function(){
        return RCNCrowdsale.new(accounts[0], accounts[0], 0, 1170000).then(function(instance){
            this.instanceRcn = instance;
            return this.instanceRcn.createTokens({from: accounts[1], value: web3.toWei('1', 'ether')});
        }).then(function(){
            return instanceRcn.token();
        }).then(function(token){
            return StandardToken.at(token);
        }).then(function(tokenInstance){
            this.token = tokenInstance;
            return token.balanceOf(accounts[1]);            
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(4000), "Account 1 should have 4000 RCN");
            return token.transfer(accounts[2], rcnToWei(1000), { from: accounts[1] });
        }).then(function(){
            return token.balanceOf(accounts[1]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(3000), "Account 1 should have 1000 RCN less");
            return token.balanceOf(accounts[2]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), rcnToWei(1000), "Account 2 should have 1000 RCN");
        });
    });
    it("Should not buy tokens, min amount limit", function(){
        return RCNCrowdsale.new(accounts[0], accounts[0], 0, 1170000).then(function(instance){
            this.instanceRcn = instance;
            return instanceRcn.token();            
        }).then(function(token){
            return StandardToken.at(token);
        }).then(function(tokenInstance){
            this.token2 = tokenInstance;
            this.instanceRcn = instance;
            return instanceRcn.createTokens({from: accounts[1], value: web3.toWei('0.09', 'ether')});
        }).catch(function(exception){
            this.savedException = exception;
        }).then(function(){
            assert.isNotNull(savedException, "Sould have throw an exception")
            return token2.balanceOf(accounts[2]);
        }).then(function(balance){
            assert.equal(balance.toNumber(), 0, "Account 1 should have 0 RCN");
        });
    })
});