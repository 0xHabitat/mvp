// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibVotingPower} from "../libraries/decisionSystem/votingPower/LibVotingPower.sol";
import {IVotingPower} from "../interfaces/IVotingPower.sol";
import {StakeContractERC20UniV3} from "../external/VotingPowerManagerERC20UniV3.sol";

interface INFPositionManagerPoolDeploy {
  function createAndInitializePoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 sqrtPriceX96
  ) external payable returns(address pool);
}

interface IERC20 {
  function totalSupply() external view returns(uint256);
}

contract VotingPowerInitUniV3 {
  event VotingPowerManagerCreated(
    address indexed votingPowerManager,
    address indexed diamondAddress
  );

  function initVotingPowerERC20UniV3(
    uint256 _precision,
    uint256 _maxAmountOfVotingPower,
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.precision = _precision;
    vp.maxAmountOfVotingPower = _maxAmountOfVotingPower;
    StakeContractERC20UniV3 stakeContract = new StakeContractERC20UniV3(
      address(this),
      _nfPositionManager,
      _governanceToken,
      _legalPairTokens
    );
    vp.votingPowerManager = address(stakeContract);
    emit VotingPowerManagerCreated(address(stakeContract), address(this));
  }

  // prerequisites: ERC20Facet is attached and diamond address is governanceToken
  // sqrtPriceX96 must be set for the pairToken at index = 0
  // _sqrtPricesX96 first value is for case token0 is diamond, second value diamond is token1
  function initVotingPowerERC20UniV3DeployMainPool(
    uint256 _precision,
    address _nfPositionManager,
    address[] memory _legalPairTokens,
    uint160[2] memory _sqrtPricesX96
  ) external {
    IVotingPower.VotingPower storage vp = LibVotingPower.votingPowerStorage();
    vp.precision = _precision;
    vp.maxAmountOfVotingPower = IERC20(address(this)).totalSupply();

    if (address(this) < _legalPairTokens[0]) {
      INFPositionManagerPoolDeploy(_nfPositionManager).createAndInitializePoolIfNecessary(address(this), _legalPairTokens[0], uint24(3000), _sqrtPricesX96[0]);
    } else {
      INFPositionManagerPoolDeploy(_nfPositionManager).createAndInitializePoolIfNecessary(_legalPairTokens[0], address(this), uint24(3000), _sqrtPricesX96[1]);
    }

    StakeContractERC20UniV3 stakeContract = new StakeContractERC20UniV3(
      address(this),
      _nfPositionManager,
      address(this),
      _legalPairTokens
    );
    vp.votingPowerManager = address(stakeContract);
    emit VotingPowerManagerCreated(address(stakeContract), address(this));
  }

  function deploy2UniV3Pools(
    address _nfPositionManager,
    address token0,
    address token1,
    uint24[2] memory fee,
    uint160 _sqrtPriceX96
  ) external {
    INFPositionManagerPoolDeploy(_nfPositionManager).createAndInitializePoolIfNecessary(token0, token1, fee[0], _sqrtPriceX96);
    INFPositionManagerPoolDeploy(_nfPositionManager).createAndInitializePoolIfNecessary(token0, token1, fee[1], _sqrtPriceX96);
  }

}
