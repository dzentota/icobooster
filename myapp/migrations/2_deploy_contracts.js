var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var SampleCrowdsale = artifacts.require("./SampleCrowdsale.sol");
var ICOBooster = artifacts.require("./ICOBooster.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(SampleCrowdsale, 1513332000, 1514196000, 20, 200000, 500000, '0xf17f52151ebef6c7334fad080c5704d77216b732');
  deployer.deploy(ICOBooster, '0x627306090abaB3A6e1400e9345bC60c78a8BEf57');
};
