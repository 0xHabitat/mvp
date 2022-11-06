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
  ) external payable returns(address pool);
}

contract ERC20Deployer {

  address weth = 0x4200000000000000000000000000000000000006;
  address nfPositionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

  event ERC20InitialDistributorDeployed(
    address indexed erc20Address,
    address indexed initialDistributor
  );

  function deployERC20InitialDistributorMainPools(
    string memory tokenName,
    string memory tokenSymbol,
    uint totalSupply,
    uint160[2] memory _sqrtPricesX96
  ) external returns(address, address) {
    InitialDistributorAbleToStake initialDistributor = new InitialDistributorAbleToStake(
      msg.sender,
      address(this)
    );

    HBT hbt = new HBT(tokenName, tokenSymbol, totalSupply, address(initialDistributor));

    require(initialDistributor.setTokenToDistribute(address(hbt)));

    emit ERC20InitialDistributorDeployed(address(hbt), address(initialDistributor));

    // deploy pools
    if (address(hbt) < weth) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(address(hbt), weth, uint24(3000), _sqrtPricesX96[0]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(address(hbt), weth, uint24(10000), _sqrtPricesX96[0]);
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(weth, address(hbt), uint24(3000), _sqrtPricesX96[1]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(weth, address(hbt), uint24(10000), _sqrtPricesX96[1]);
    }
    return (address(hbt), address(initialDistributor));
  }

  function deployLastPool(address hbt, uint160[2] memory _sqrtPricesX96) external {
    if (hbt < weth) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(hbt, weth, uint24(500), _sqrtPricesX96[0]);
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(weth, hbt, uint24(500), _sqrtPricesX96[1]);
    }
  }

  function deployThreePools(address hbt, address pairAddress, uint160[2] memory _sqrtPricesX96) external {
    if (hbt < pairAddress) {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(hbt, pairAddress, uint24(3000), _sqrtPricesX96[0]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(hbt, pairAddress, uint24(10000), _sqrtPricesX96[0]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(hbt, pairAddress, uint24(500), _sqrtPricesX96[0]);
    } else {
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(pairAddress, hbt, uint24(3000), _sqrtPricesX96[1]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(pairAddress, hbt, uint24(10000), _sqrtPricesX96[1]);
      INFPositionManagerPoolDeploy(nfPositionManager).createAndInitializePoolIfNecessary(pairAddress, hbt, uint24(500), _sqrtPricesX96[1]);
    }
  }
}
