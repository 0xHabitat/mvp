// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "../../libraries/openzeppelin/IERC20.sol";
import {SafeERC20} from "../../libraries/openzeppelin/SafeERC20.sol";

contract InitialDistributor {
  using SafeERC20 for IERC20;

  address owner;
  address tokenToDistribute;

  constructor(address _owner, address _tokenToDistribute) {
    owner = _owner;
    tokenToDistribute = _tokenToDistribute;
  }

  function distribute(address receiver, uint256 amount) internal {
    IERC20(tokenToDistribute).safeTransfer(receiver, amount);
  }

  function distributeMultiple(address[] memory receivers, uint256[] memory amounts) external {
    require(msg.sender == owner, "No rights to distribute");
    require(receivers.length == amounts.length, "Input length does not match");
    require(receivers.length <= 500, "No more than 500 per tx");
    for (uint256 i = 0; i < receivers.length; i++) {
      distribute(receivers[i], amounts[i]);
    }
  }
}

interface IStakeERC20Contract {
  function stakeGovInFavorOf(address beneficiary, uint256 _amount) external;
}

contract InitialDistributorAbleToStake {
  using SafeERC20 for IERC20;

  address owner;
  address tokenSetter;
  address tokenToDistribute;
  address stakeERC20Contract;

  constructor(address _owner, address _tokenSetter) {
    owner = _owner;
    tokenSetter = _tokenSetter;
  }

  function setStakeERC20Contract(address _stakeERC20Contract) external {
    require(msg.sender == owner, "No rights to set contract");
    stakeERC20Contract = _stakeERC20Contract;
  }

  function setTokenToDistribute(address _token) external returns (bool) {
    require(msg.sender == tokenSetter, "No rights to set contract");
    tokenToDistribute = _token;
    return true;
  }

  function stakeTokensInFavorOfMultipleAddresses(
    address[] memory beneficiaries,
    uint256[] memory amounts,
    uint256 totalAmount
  ) external {
    require(msg.sender == owner, "No rights to stake");
    require(beneficiaries.length == amounts.length, "input length does not match");
    IERC20(tokenToDistribute).approve(stakeERC20Contract, totalAmount);
    uint256 amountStaked;
    for (uint256 i = 0; i < beneficiaries.length; i++) {
      IStakeERC20Contract(stakeERC20Contract).stakeGovInFavorOf(beneficiaries[i], amounts[i]);
      amountStaked += amounts[i];
    }
    require(amountStaked == totalAmount, "Bad input");
  }

  function distribute(address receiver, uint256 amount) internal {
    IERC20(tokenToDistribute).safeTransfer(receiver, amount);
  }

  function distributeMultiple(address[] memory receivers, uint256[] memory amounts) external {
    require(msg.sender == owner, "No rights to distribute");
    require(receivers.length == amounts.length, "Input length does not match");
    require(receivers.length <= 500, "No more than 500 per tx");
    for (uint256 i = 0; i < receivers.length; i++) {
      distribute(receivers[i], amounts[i]);
    }
  }
}
