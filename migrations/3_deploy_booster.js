const ICOBooster = artifacts.require("ICOBooster");

module.exports = function(deployer) {
    //constructor arguments only for demo! You should be used real data for deploy
    deployer.deploy(ICOBooster, '0xCd865A5DC875b9c1Aa73535490E2C98f201A71F6');
};
