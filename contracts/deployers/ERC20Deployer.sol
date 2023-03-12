// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {InitialDistributorAbleToStake} from "../external/token/InitialDistributor.sol";
import {HBT} from "../external/token/HBT.sol";

interface INFPositionManagerPoolDeploy {
  function createAndInitializePoolIfNecessary(
    address token0,
    address token1,
    uint24 fee,
    uint160 sqrtPriceX96
  ) external payable returns (address pool);
}

/**
 * @title ERC20Deployer - Allows to deploy a new erc20 token, the initial distributor contract and main uniV3 pools for it.
 * @author @roleengineer
 */
contract ERC20Deployer {
  address weth = 0x4200000000000000000000000000000000000006;
  address nfPositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

  event ERC20InitialDistributorDeployed(
    address indexed erc20Address,
    address indexed initialDistributor
  );

  /**
   * @notice Deploys a erc20 token, the initial distributor contract and main uniV3 pools for it on optimism.
   * @param tokenName String represents erc20 token name.
   * @param tokenSymbol String represents erc20 token symbol.
   * @param totalSupply Sets fixed totalSupply (no minting after).
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools (with weth as a pair). First price is used if new token is token0, second if new token is token1.
   * @param initialDistributorOwner Address which is allowed to distribute token (by calling initialDistributor).
   * @return Address of the new erc20 token contract.
   *         Address of the new initial distributor contract.
   */
  function deployERC20InitialDistributorMainPools(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 totalSupply,
    uint160[2] memory _sqrtPricesX96,
    address initialDistributorOwner
  ) external returns (address, address) {
    InitialDistributorAbleToStake initialDistributor = new InitialDistributorAbleToStake(
      initialDistributorOwner,
      address(this)
    );

    HBT hbt = new HBT(tokenName, tokenSymbol, totalSupply, address(initialDistributor));

    require(initialDistributor.setTokenToDistribute(address(hbt)));

    emit ERC20InitialDistributorDeployed(address(hbt), address(initialDistributor));

    // deploy pools
    if (address(hbt) < weth) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        address(hbt),
        weth,
        uint24(3000),
        _sqrtPricesX96[0]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        address(hbt),
        weth,
        uint24(10000),
        _sqrtPricesX96[0]
      );
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        weth,
        address(hbt),
        uint24(3000),
        _sqrtPricesX96[1]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        weth,
        address(hbt),
        uint24(10000),
        _sqrtPricesX96[1]
      );
    }
    return (address(hbt), address(initialDistributor));
  }

  /**
   * @notice Deploys the last main pool (which was not deployed, because of 15mln optimism gas limit).
   * @param hbt Address of newly deployed erc20 token contract.
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools (with weth as a pair). First price is used if hbt is token0, second if hbt is token1.
   */
  function deployLastPool(address hbt, uint160[2] memory _sqrtPricesX96) external {
    if (hbt < weth) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        hbt,
        weth,
        uint24(500),
        _sqrtPricesX96[0]
      );
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        weth,
        hbt,
        uint24(500),
        _sqrtPricesX96[1]
      );
    }
  }

  /**
   * @notice Deploys three uniV3 pools (fees: 1%, 0.3%, 0.05%).
   * @param hbt Address of newly deployed erc20 token contract.
   * @param pairAddress Address of erc20 token - new pair.
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools. First price is used if hbt is token0, second if hbt is token1.
   */
  function deployThreePools(
    address hbt,
    address pairAddress,
    uint160[2] memory _sqrtPricesX96
  ) external {
    if (hbt < pairAddress) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        hbt,
        pairAddress,
        uint24(3000),
        _sqrtPricesX96[0]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        hbt,
        pairAddress,
        uint24(10000),
        _sqrtPricesX96[0]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        hbt,
        pairAddress,
        uint24(500),
        _sqrtPricesX96[0]
      );
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        pairAddress,
        hbt,
        uint24(3000),
        _sqrtPricesX96[1]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        pairAddress,
        hbt,
        uint24(10000),
        _sqrtPricesX96[1]
      );
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(
        pairAddress,
        hbt,
        uint24(500),
        _sqrtPricesX96[1]
      );
    }
  }
}
