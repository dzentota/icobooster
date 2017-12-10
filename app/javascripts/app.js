// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import booster_artifacts from '../../build/contracts/ICOBooster.json'

// ICOPool is our usable abstraction, which we'll use through the code below.
var ICOBooster = contract(booster_artifacts);

// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;

window.App = {
    start: function() {
        var self = this;

        // Bootstrap the ICOBooster abstraction for Use.
        ICOBooster.setProvider(web3.currentProvider);
        ICOBooster.defaults({
            from: account,
            gas: 4712388,
            gasPrice: 100000000000
        })

        // Get the initial account balance so it can be displayed.
        web3.eth.getAccounts(function(err, accs) {
            if (err != null) {
                alert("There was an error fetching your accounts.");
                return;
            }

            if (accs.length == 0) {
                alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
                return;
            }

            accounts = accs;
            account = accounts[0];

            self.refreshBalance();
            self._updateMeta();
        });
    },

    setStatus: function(message) {
        var status = document.getElementById("status");
        status.innerHTML = message;
    },

    _updateMeta: function() {
        var self = this;
        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.getStartTime.call(1, {from: account});
        }).then(function(value) {
            var start_element = document.getElementById("start");
            start_element.value = value.valueOf();
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error getting meta; see log.");
        });

        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.getEndTime.call(1, {from: account});
        }).then(function(value) {
            var end_element = document.getElementById("end");
            end_element.value = value.valueOf();
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error getting meta; see log.");
        });
    },

    refreshBalance: function() {
        var self = this;
        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.getWeiRaised.call(1, {from: account});
        }).then(function(value) {
            var balance_element = document.getElementById("balance");
            balance_element.innerHTML = value.valueOf();
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error getting balance; see log.");
        });
    },

    contribute: function(campaignId) {
        var self = this;

        this.setStatus("Initiating transaction... (please wait)");

        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.contribute(campaignId, {from: account, value: 20000});
        }).then(function() {
            self.setStatus("Transaction complete!");
            self.refreshBalance();
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error sending coin; see log.");
        });
    },

    getCampaignIds: function() {
        var self = this;

        this.setStatus("Sending request... (please wait)");

        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.getCampaignIds.call({from: account});
        }).then(function(value) {
            value.forEach(function(el){
               console.log(el.toNumber());
            });
            self.setStatus("success!");
            // console.log(value);
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error; see log.");
        });
    },

    updateStartTime: function(campaignId, start) {
        var self = this;

        this.setStatus("Initiating transaction... (please wait)");

        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.updateStartTime(campaignId, start, {from: account});
        }).then(function() {
            self.setStatus("Transaction complete!");
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error sending coin; see log.");
        });
    },

    updateEndTime: function(campaignId, end) {
        var self = this;

        this.setStatus("Initiating transaction... (please wait)");

        var meta;
        ICOBooster.deployed().then(function(instance) {
            meta = instance;
            return meta.updateEndTime(campaignId, end, {from: account});
        }).then(function() {
            self.setStatus("Transaction complete!");
        }).catch(function(e) {
            console.log(e);
            self.setStatus("Error sending coin; see log.");
        });
    },
    createCampaign: function() {
        //newCampaign(uint256 _campaignId, uint256 _startTime, uint256 _endTime, uint256 _minInvestment, uint256 _cap, uint256 _hardCap, uint256 _oneAddressLimit,  address _crowdSaleAddress, address _tokenAddress)
            var self = this;
            this.setStatus("Initiating transaction... (please wait)");
            var meta;
            ICOBooster.deployed().then(function(instance) {
                meta = instance;
                return meta.newCampaign(
                    1, 1513332000, 1514196000, 1, 5, 20, 20, 0xf17f52151ebef6c7334fad080c5704d77216b732, 0xf17f52151ebef6c7334fad080c5704d77216b732
                    , {from: account});
            }).then(function() {
                self.setStatus("Transaction complete!");
                self.refreshBalance();
            }).catch(function(e) {
                console.log(e);
                self.setStatus("Error sending coin; see log.");
            });
    }
};

window.addEventListener('load', function() {
    // Checking if Web3 has been injected by the browser (Mist/MetaMask)
    if (typeof web3 !== 'undefined') {
        console.warn("Using web3 detected from external source. If you find that your accounts don't appear, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
        // Use Mist/MetaMask's provider
        window.web3 = new Web3(web3.currentProvider);
    } else {
        console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
        // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
        window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
    }

    App.start();
});
