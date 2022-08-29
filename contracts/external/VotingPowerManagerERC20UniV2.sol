// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "../libraries/openzeppelin/IERC20.sol";
import {SafeERC20} from "../libraries/openzeppelin/SafeERC20.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";

contract StakeContractERC20UniV2 {
  using SafeERC20 for IERC20;

  IVotingPower votingPower;
  uint256 precision;
  // 2500HBT 1.25ETH -> 0.000043241Univ2
  // governanceToken => coefficient
  mapping(address => uint256) tokensMultiplier;
  // holder => govToken => staked amount
  mapping(address => mapping(address => uint256)) stakedHoldings;

  constructor(
    address _votingPower,
    uint256 _precision,
    address[] memory _governanceTokens,
    uint256[] memory coefficients
  ) {
    require(_votingPower != address(0)); // diamond address
    require(_governanceTokens.length == coefficients.length, "Different arrays length");
    precision = _precision;
    votingPower = IVotingPower(_votingPower);
    for (uint256 i = 0; i < _governanceTokens.length; i++) {
      tokensMultiplier[_governanceTokens[i]] = coefficients[i]; // coefficient - 1000 = 1.0
    }
  }

  // should give token approval before call
  function stake(address _governanceToken, uint256 _amount) public {
    require(tokensMultiplier[_governanceToken] > 0, "Token is not accepted as a governance one.");
    // receive tokens from holder to stake contract
    IERC20(_governanceToken).safeTransferFrom(msg.sender, address(this), _amount); // double check
    // account how much holders tokens are staked
    stakedHoldings[msg.sender][_governanceToken] += _amount;
    // give voting power
    uint256 multiplier = tokensMultiplier[_governanceToken];
    uint256 amountOfVotingPower = (_amount * multiplier) / precision;
    votingPower.increaseVotingPower(msg.sender, amountOfVotingPower);
  }

  function unstake(address _governanceToken, uint256 _amount) public {
    require(
      stakedHoldings[msg.sender][_governanceToken] >= _amount,
      "Trying to unstake more than have"
    );
    // take back voting power
    uint256 multiplier = tokensMultiplier[_governanceToken];
    uint256 amountOfVotingPower = (_amount * multiplier) / precision;
    votingPower.decreaseVotingPower(msg.sender, amountOfVotingPower);
    // reduce token holdings
    stakedHoldings[msg.sender][_governanceToken] -= _amount;
    // transfer tokens from stake contract to holder
    IERC20(_governanceToken).safeTransfer(msg.sender, _amount);
  }

  function getStakedBalanceOfGovernanceToken(address holder, address _governanceToken)
    external
    view
    returns (uint256 balance)
  {
    balance = stakedHoldings[holder][_governanceToken];
  }

  // should give approvals for all tokens before call
  function stakeMultiple(address[] memory _governanceTokens, uint256[] memory _amounts) external {
    require(_governanceTokens.length == _amounts.length, "Different array length");
    for (uint256 i = 0; i < _governanceTokens.length; i++) {
      stake(_governanceTokens[i], _amounts[i]);
    }
  }

  function unstakeMultiple(address[] memory _governanceTokens, uint256[] memory _amounts) external {
    require(_governanceTokens.length == _amounts.length, "Different array length");
    for (uint256 i = 0; i < _governanceTokens.length; i++) {
      unstake(_governanceTokens[i], _amounts[i]);
    }
  }
}
