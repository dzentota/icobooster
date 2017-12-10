const ICOBooster = artifacts.require("ICOBooster");

module.exports = function(deployer) {
    //constructor arguments only for demo! You should be used real data for deploy
    deployer.deploy(ICOBooster, '0x627306090abaB3A6e1400e9345bC60c78a8BEf57');
};
