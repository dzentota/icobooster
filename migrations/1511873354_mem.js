var Mem = artifacts.require("./Mem.sol");

module.exports = function(deployer) {
  const tokenAmount = 1400000;
  deployer.deploy(Mem, tokenAmount);
};
