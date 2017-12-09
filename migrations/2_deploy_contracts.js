const SampleCrowdsale = artifacts.require("SampleCrowdsale");

module.exports = function(deployer) {
    //constructor arguments only for demo! You should be used real data for deploy
    deployer.deploy(SampleCrowdsale
        , 1513332000, 1514196000, 20, 200000, 500000, '0xCEa97F4bb659021b88b091CF2c6545A1Bb1C8891'
    );
};
