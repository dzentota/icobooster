var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "transfer erosion hunt round betray unique fatigue beauty twice bless around echo";

module.exports = {
    // Deploy to Ropten using infura
    networks: {
        ropsten: {
            provider: function() {
                return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/2t9moYtXJAAKeyV0BTng")
            },
            network_id: 3,
            gas: 1712388
        }
    }
};
