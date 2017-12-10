pragma solidity ^0.4.4;

import "./math/SafeMath.sol";
import "./token/ERC20.sol";
import "./crowdsale/RefundVault.sol";

/**
*/
contract ICOBooster is Ownable {
    using SafeMath for uint256;

    uint8 public FEE = 1;

    uint8 public constant decimals = 18;

    uint256 private constant UNIT = 10 ** uint256(decimals);

    address public owner;

    enum State {Active, Refunding, Closed}

    struct Campaign {
    // start timestamp where investments are allowed (inclusive)
    uint256 startTime;
    // end timestamp where investments are allowed (inclusive)
    uint256 endTime;
    ERC20 token;
    //beneficiary
    address beneficiary;
    //soft cap in wei
    uint cap;
    //hard cap in wei
    uint hardCap;
    //minimal investment in Wei
    uint minInvestment;
    // Address where funds are collected
    RefundVault wallet;
    //how much money can be payed from one address (could be set by ICO)
    uint256 oneAddressLimit;
    // raised in wei
    uint256 weiRaised;
    // How many tokens were bought
    uint256 tokensBought;
    // Amount of tokens that were sold
    // Investor contributions
    mapping (address => uint256) balances;
    mapping (address => uint256) tokens;
    uint index;
    State state;
    }

    //Campaign index
    uint256[] campaignIndex;

    // id => Campaign
    mapping (uint => Campaign) campaigns;

    function campaignExist(uint campaignId) internal constant returns (bool exists)
    {
        if (campaignIndex.length == 0) return false;
        return (campaignIndex[campaigns[campaignId].index] == campaignId);
    }

    event LogNewCampaign(uint256 indexed campaignId, uint256 index, uint256 startTime, uint256 endTime, uint256 minInvestment, uint256 cap, uint256 hardCap, address crowdSaleAddress, address tokenContactAddress);

    event LogInvestment(uint indexed campaignId, address indexed funder, uint256 value);

    event LogClosed(uint256 campaignId);

    event LogRefundingEnabled(uint256 indexed campaignId);

    event LogRefunded(uint256 indexed campaignId, address indexed funder);

    function ICOBooster(address _owner) public
    {
        require(_owner != address(0));
        owner = _owner;
    }

    function newCampaign(uint256 _campaignId, uint256 _startTime, uint256 _endTime, uint256 _minInvestment, uint256 _cap, uint256 _hardCap, uint256 _oneAddressLimit,  address _crowdSaleAddress, address _tokenAddress) public onlyOwner returns(uint index) {
//        require(_startTime > now + 10 minutes);
        require(_endTime > _startTime);
        require(_minInvestment > 0);
        require(_cap > _minInvestment);
        require(_hardCap >= _cap);
        require(_crowdSaleAddress != address(0));

        campaigns[_campaignId].startTime = _startTime;
        campaigns[_campaignId].endTime = _endTime;
        campaigns[_campaignId].cap = _cap.mul(UNIT);
        campaigns[_campaignId].hardCap = _hardCap.mul(UNIT);
        campaigns[_campaignId].minInvestment = _minInvestment;
        campaigns[_campaignId].beneficiary = _crowdSaleAddress;
        campaigns[_campaignId].token = ERC20(_tokenAddress);
        campaigns[_campaignId].state = State.Active;
        campaigns[_campaignId].weiRaised = 0;
        campaigns[_campaignId].wallet = new RefundVault(this);
        campaigns[_campaignId].oneAddressLimit = _oneAddressLimit;
        

        campaigns[_campaignId].index = campaignIndex.push(_campaignId) - 1;
        LogNewCampaign(_campaignId, campaigns[_campaignId].index, _startTime, _endTime, _minInvestment, _cap, _hardCap, _crowdSaleAddress, _tokenAddress);

        return campaignIndex.length - 1;
    }

    function contribute(uint256 campaignId) external payable {
        require(campaignExist(campaignId));
        require(validPurchase(campaignId));
        require(campaigns[campaignId].state == State.Active);

        uint256 weiAmount = msg.value;
        uint256 returnToSender = 0;

        Campaign storage c = campaigns[campaignId];
        // Distribute only the remaining tokens if final contribution exceeds hard cap
        if (c.weiRaised.add(weiAmount) > c.hardCap) {
            uint256 diff = c.hardCap.sub(c.weiRaised);
            returnToSender = msg.value.sub(diff);
            weiAmount = msg.value.sub(returnToSender);
        }
        c.weiRaised = c.weiRaised.add(weiAmount);

        // update balance
        c.balances[msg.sender] = c.balances[msg.sender].add(weiAmount);

        LogInvestment(campaignId, msg.sender, weiAmount);
        // Forward funds
        c.wallet.deposit.value(weiAmount)(msg.sender);
        // Return funds that are over hard cap
        if (returnToSender > 0) {
            msg.sender.transfer(returnToSender);
        }
    }

    // @return true if the transaction can buy tokens
    function validPurchase(uint256 campaignId) internal view returns (bool) {
        bool withinPeriod = now >= campaigns[campaignId].startTime && now <= campaigns[campaignId].endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool greaterThanMinInvestment = msg.value > campaigns[campaignId].minInvestment;
//        bool withinHardCap = campaigns[campaignId].weiRaised.add(msg.value) <= campaigns[campaignId].hardCap;
        return withinPeriod && nonZeroPurchase && greaterThanMinInvestment
//        && withinHardCap
        ;
    }

    // @return true if campaign has ended or cap is reached
    function hasEnded(uint campaignId) public view returns(bool) {
        bool hardCapReached = campaigns[campaignId].weiRaised >= campaigns[campaignId].hardCap;
        return now > campaigns[campaignId].endTime || hardCapReached;
    }

    function checkGoalReached(uint campaignId) public returns(bool reached) {
        Campaign storage c = campaigns[campaignId];
        require(c.state != State.Closed);
        if (c.weiRaised < c.cap)
        return false;
        uint amount = c.weiRaised;
        c.wallet.close();
        c.beneficiary.transfer(amount);
        c.tokensBought = c.token.balanceOf(this);
//        c.tokensBought = c.token.call(bytes4(sha3("balanceOf(this)")));
        c.state = State.Closed;
        LogClosed(campaignId);
        return true;
    }

    function claimTokens(uint256 campaignId) public {
        Campaign storage c = campaigns[campaignId];
        require(c.state == State.Closed);
        require(c.balances[msg.sender] > 0);
        uint256 _tokens = calculateTokens(campaignId, msg.sender);
        c.balances[msg.sender] = 0;
        c.tokens[msg.sender] = c.tokens[msg.sender].add(_tokens);
        campaigns[campaignId].token.transfer(msg.sender, _tokens);
    }

    function calculateTokens(uint256 campaignId, address funder) internal returns(uint256 tokens)
    {
        uint256 tokensFee = campaigns[campaignId].tokensBought.mul(FEE).div(100);
        uint256 availableTokens = campaigns[campaignId].tokensBought.sub(tokensFee);
        return campaigns[campaignId].balances[funder].div(campaigns[campaignId].weiRaised.div(availableTokens));
    }

    function claimRefund(uint256 campaignId) public {
        Campaign storage c = campaigns[campaignId];
        require(hasEnded(campaignId));
        require(c.weiRaised < c.cap);
        if (c.state == State.Active) {
            c.wallet.enableRefunds();
            c.state = State.Refunding;
            LogRefundingEnabled(campaignId);
        }
        c.wallet.refund(msg.sender);
        LogRefunded(campaignId, msg.sender);
    }

    function updateStartTime(uint256 campaignId, uint256 _startTime) public onlyOwner {
        Campaign storage c = campaigns[campaignId];
        c.startTime = _startTime;
    }

    function updateEndTime(uint256 campaignId, uint256 _endTime) public onlyOwner {
        Campaign storage c = campaigns[campaignId];
        c.endTime = _endTime;
    }

    function updateCrowdsaleAddress(uint256 campaignId, address _beneficiary) public onlyOwner {
        Campaign storage c = campaigns[campaignId];
        c.beneficiary = _beneficiary;
    }

    function updateTokenAddress(uint256 campaignId, address _token) public onlyOwner
    {
        Campaign storage c = campaigns[campaignId];
        c.token = ERC20(_token);
    }

    function getWeiRaised(uint256 campaignId) public constant returns(uint256 weiRaised)
    {
        return campaigns[campaignId].weiRaised;
    }

    function getCampaignIds() public constant returns (uint256[])
    {
        return campaignIndex;
    }

    function getStartTime(uint256 campaignId) public constant returns(uint256 startTime) {
        return campaigns[campaignId].startTime;
    }

    function getEndTime(uint256 campaignId) public constant returns(uint256 endTime) {
        return campaigns[campaignId].endTime;
    }

    function () public payable {}

}
