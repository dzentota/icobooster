const SampleCrowdsale = artifacts.require("SampleCrowdsale");

module.exports = function(deployer) {
    //constructor arguments only for demo! You should be used real data for deploy
    deployer.deploy(SampleCrowdsale
        , 1513332000, 1514196000, 20, 200000, 500000, '0xf17f52151ebef6c7334fad080c5704d77216b732'
    );
};
