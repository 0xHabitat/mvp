// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "../../libraries/openzeppelin/IERC20.sol";
import {SafeERC20} from "../../libraries/openzeppelin/SafeERC20.sol";

/**
 * @title InitialDistributor - Contract receives the whole totalSupply of newly deployed erc20 token
 *        (without minting after deployment) and has functionality to distribute this token.
 * @author @roleengineer
 */
contract InitialDistributor {
  using SafeERC20 for IERC20;

  address owner;
  address tokenToDistribute;

  /**
   * @notice Constructor function sets the erc20 token and an address which is able to distribute it.
   * @param _owner Address which is able to distribute erc20 token.
   * @param _tokenToDistribute Address of erc20 token, which should be distributed.
   */
  constructor(address _owner, address _tokenToDistribute) {
    owner = _owner;
    tokenToDistribute = _tokenToDistribute;
  }

  function distribute(address receiver, uint256 amount) internal {
    IERC20(tokenToDistribute).safeTransfer(receiver, amount);
  }

  /**
   * @notice Method transfers `amounts` of erc20 token to the `receivers`
   *         Arrays receivers and amounts must be same length.
   * @dev    On optimism the part of tx cost based on gas usage is very low,
   *         so it allows to make token distribution to hundreds of addresses in one tx.
   * @param receivers Array of addresses which will receive erc20 token.
   * @param amounts Array of erc20 token amounts that receivers addresses should get accordingly.
   */
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

/**
 * @title InitialDistributorAbleToStake - Extends InitialDistributor with ability
 *        to stake erc20 token inside StakeContractERC20UniV3 in favor of beneficiaries.
 * @author @roleengineer
 */
contract InitialDistributorAbleToStake is InitialDistributor {
  using SafeERC20 for IERC20;

  address tokenSetter;
  address stakeERC20Contract;

  /**
   * @notice Constructor function sets the address, which is able to set erc20 token
   *         and the address which is able to distribute it and set stake contract.
   * @param _owner Address which is able to distribute erc20 token and set stake contract.
   * @param _tokenSetter Address which is able to set erc20 token.
   */
  constructor(address _owner, address _tokenSetter) InitialDistributor(_owner, address(0)) {
    owner = _owner;
    tokenSetter = _tokenSetter;
  }

  /**
   * @notice Method sets stake contract address (StakeContractERC20UniV3).
   * @dev Stake contract must have function from IStakeERC20Contract interface.
   * @param _stakeERC20Contract Address of stake contract.
   */
  function setStakeERC20Contract(address _stakeERC20Contract) external {
    require(msg.sender == owner, "No rights to set contract");
    stakeERC20Contract = _stakeERC20Contract;
  }

  /**
   * @notice Method sets erc20 token contract address.
   * @param _token Address of erc20 token contract.
   * @return True
   */
  function setTokenToDistribute(address _token) external returns (bool) {
    require(msg.sender == tokenSetter, "No rights to set contract");
    tokenToDistribute = _token;
    return true;
  }

  /**
   * @notice Method distributes erc20 tokens in such way: array of beneficiaries
   *         addresses will get staked amounts of governance tokens inside stake
   *         contract (and voting power as well)
   * @dev Method calls stake contract function stakeGovInFavorOf for every beneficiary address
   *      (in beneficiaries array) with respective amount from amounts array.
   *      By doing this each beneficiary saves 2 optimism txs (approve stake contract and stakeGovToken).
   * @param beneficiaries Array of addresses which will receive staked governance token and respective voting power.
   * @param amounts Array of erc20 token amounts that will be staked in favor of beneficiaries addresses.
   * @param totalAmount The sum of all elements of `amounts` array.
   */
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
}
