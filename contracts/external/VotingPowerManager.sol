// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IERC20 } from "../libraries/openzeppelin/IERC20.sol";
import { SafeERC20 } from "../libraries/openzeppelin/SafeERC20.sol";
import { ITreasuryVotingPower } from "../interfaces/treasury/ITreasuryVotingPower.sol";

contract StakeContract {
  using SafeERC20 for IERC20;

  address admin;
  ITreasuryVotingPower votingPower;
  // governanceToken => coefficient
  mapping(address => uint256) tokensMultiplier;
  // holder => govToken => staked amount
  mapping(address => mapping(address => uint)) stakedHoldings;

  constructor(address _admin, address _votingPower, address[] memory _governanceTokens, uint256[] memory coefficients) {
    require(_votingPower != address(0)); // diamond address
    require(_governanceTokens.length == coefficients.length, "Different arrays length");
    admin = _admin;
    votingPower = ITreasuryVotingPower(_votingPower);
    for (uint i = 0; i < _governanceTokens.length; i++) {
      tokensMultiplier[_governanceTokens[i]] = coefficients[i]; // coefficient - 1000 = 1.0
    }
  }

  // should give token approval before call
  function stake(address _governanceToken, uint _amount) public {
    require(tokensMultiplier[_governanceToken] > 0, "Token is not accepted as a governance one.");
    // receive tokens from holder to stake contract
    IERC20(_governanceToken).safeTransferFrom(msg.sender, address(this), _amount); // double check
    // account how much holders tokens are staked
    stakedHoldings[msg.sender][_governanceToken] += _amount;
    // give voting power
    uint multiplier = tokensMultiplier[_governanceToken];
    uint amountOfVotingPower = _amount * multiplier / 1000;
    votingPower.increaseVotingPower(msg.sender, amountOfVotingPower);
  }

  function unstake(address _governanceToken, uint _amount) public {
    bool notAbleToUnstake = votingPower.hasVotedInActiveProposals(msg.sender);
    require(!notAbleToUnstake, "Not able to unstake at the moment");
    require(stakedHoldings[msg.sender][_governanceToken] >= _amount, "Trying to unstake more than have");
    // take back voting power
    uint multiplier = tokensMultiplier[_governanceToken];
    uint amountOfVotingPower = _amount * multiplier / 1000;
    votingPower.decreaseVotingPower(msg.sender, amountOfVotingPower);
    // reduce token holdings
    stakedHoldings[msg.sender][_governanceToken] -= _amount;
    // transfer tokens from stake contract to holder
    IERC20(_governanceToken).safeTransfer(msg.sender, _amount);
  }

  function getStakedBalanceOfGovernanceToken(address holder, address _governanceToken) external view returns(uint256 balance) {
    balance = stakedHoldings[holder][_governanceToken];
  }

  // should give approvals for all tokens before call
  function stakeMultiple(address[] memory _governanceTokens, uint[] memory _amounts) external {
    require(_governanceTokens.length == _amounts.length, "Different array length");
    for (uint i = 0; i < _governanceTokens.length; i++) {
      stake(_governanceTokens[i], _amounts[i]);
    }
  }

  function unstakeMultiple(address[] memory _governanceTokens, uint[] memory _amounts) external {
    require(_governanceTokens.length == _amounts.length, "Different array length");
    for (uint i = 0; i < _governanceTokens.length; i++) {
      unstake(_governanceTokens[i], _amounts[i]);
    }
  }
  // Admin stuff

  function addGovernanceToken(address _governanceToken, uint256 coefficient) external {
    require(msg.sender == admin, "No permission");
    tokensMultiplier[_governanceToken] = coefficient;
  }

  function removeGovernanceToken(address _governanceToken) public {
    require(msg.sender == admin, "No permission");
    require(IERC20(_governanceToken).balanceOf(address(this)) == 0, "All tokens must be unstaked.");
    tokensMultiplier[_governanceToken] = 0;
  }

  function forceUnstakeGovernanceToken(address _governanceToken, address[] memory holders) public {
    require(msg.sender == admin, "No permission");
    for (uint i = 0; i < holders.length; i++) {
      address holder = holders[i];
      uint amount = stakedHoldings[holder][_governanceToken];
      // take back voting power
      uint multiplier = tokensMultiplier[_governanceToken];
      uint amountOfVotingPower = amount * multiplier / 1000;
      votingPower.decreaseVotingPower(msg.sender, amountOfVotingPower);
      // send tokens to holder
      IERC20(_governanceToken).safeTransfer(holder, amount);
    }
  }

  function forceRemoveGovernanceToken(address _governanceToken, address[] memory holders) external {
    forceUnstakeGovernanceToken(_governanceToken, holders);
    removeGovernanceToken(_governanceToken);
  }


}

contract SignersSetter {
  // a.k.a. gnosis but one votingPower - one address
}
