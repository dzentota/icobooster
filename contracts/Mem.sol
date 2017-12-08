pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/token/MintableToken.sol";

contract Mem is MintableToken {
  string public name = "Mem Token";
  string public symbol = "MEM";
  uint public decimals = 18;

  function Mem(uint256 _amount) public {
    owner = msg.sender;
    mint(owner, _amount);
  }
}
