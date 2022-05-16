// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {HabitatDiamond} from "./HabitatDiamond.sol";
import {IDAO} from "./interfaces/dao/IDAO.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "./interfaces/IAddressesProvider.sol";
import {IManagementSystem} from "./interfaces/dao/IManagementSystem.sol";
import {IUniswapV2Factory} from "./interfaces/token/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/token/IUniswapV2Pair.sol";
import {IWETH} from "./interfaces/token/IWETH.sol";
import {IERC20} from "./libraries/openzeppelin/IERC20.sol";

struct Token {
  string tokenName;
}
/*
enum ETHPair {
  None,
  UniV2,
  Sushi,
  UniPlusSushi
}

struct VPMTokens {
  VPMToken nativeGovernanceToken;
  VPMToken uniDerivative;
  VPMToken sushiDerivative;
}

struct VPMToken {
  uint coefficient;
  //uint price
}
*/
contract HabitatDiamondFactory {

  function deployHabitatDiamond(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    IManagementSystem.VotingSystems memory _vs,
    IManagementSystem.Signers memory _s,
    bytes memory habitatDiamondConstructorArgs,
    ETHPair ethPair
  ) external payable returns(address habitatDiamond) {
    // deploy HabitatDiamond
    // first param contractOwner - setting Factory as contractOwner and at the end of call move ownership to msg.sender -> later need to adjust replacing ownership logic to voting logic (a.k.a. Diamond is owner of itself)
    bytes memory habitatDiamondConstructorArgs = abi.encode(address(this), addressesProvider, daoMetaData);
    bytes memory bytecode = bytes.concat(type(HabitatDiamond).creationCode, habitatDiamondConstructorArgs);
    assembly {
      habitatDiamond := create(0, add(bytecode, 32), mload(bytecode))
    }
    // second deploy HBT token


    // deploy ETHPair
    address uniV2Pair;
    uint uniV2coefficient;
    address sushiV2Pair;
    uint sushiV2coefficient;
    address wETH = IAddressesProvider(addressesProvider).getWETH();
    if (ethPair == ETHPair.UniPlusSushi) {
      address uniswapV2Factory = IAddressesProvider(addressesProvider).getUniswapV2Factory();
      (uniV2Pair, uniV2coefficient) = createV2Pair(uniswapV2Factory, habitatDiamond, wETH);
      address sushiV2Factory = IAddressesProvider(addressesProvider).getSushiV2Factory();
      (sushiV2Pair, sushiV2coefficient) = createV2Pair(sushiV2Factory, habitatDiamond, wETH);
    } else {
      if (ethPair == ETHPair.UniV2) {
        address uniswapV2Factory = IAddressesProvider(addressesProvider).getUniswapV2Factory();
        (uniV2Pair, uniV2coefficient) = createV2Pair(uniswapV2Factory, habitatDiamond, wETH);
      } else if (ethPair == ETHPair.Sushi) {
        address sushiV2Factory = IAddressesProvider(addressesProvider).getSushiV2Factory();
        (sushiV2Pair, sushiV2coefficient) = createV2Pair(sushiV2Factory, habitatDiamond, wETH);
      }
    }

    // VotingPowerInit if needed
    // make cutting

    // move ownership to msg.sender
    bytes memory transferOwnershipCall = abi.encodeWithSignature('transferOwnership(address)', msg.sender);
    (bool suc,) = habitatDiamond.call(transferOwnershipCall);
    require(suc);
  }

  function createV2Pair(address factoryAddress, address habitatDiamond, address wETH) internal returns(address pairAddress, uint coefficient) {
    // replace later with the price, now 0.1ETH - 100HBT
    uint amountETH = msg.value;
    require(amountETH == 100000000 gwei);
    IWETH(wETH).deposit{value: amountETH}();
    pairAddress = IUniswapV2Factory(factoryAddress).createPair(habitatDiamond, wETH);
    uint amountGovToken = 100 * 10 ** 18;
    // before in HBTDiamond constructor we must transfer 100 * 10 ** 18 to this contract
    assert(IWETH(wETH).transfer(pairAddress, amountETH));
    assert(IERC20(habitatDiamond).transfer(pairAddress, amountGovToken));
    IUniswapV2Pair(pairAddress).mint(habitatDiamond);
    coefficient = IERC20(pairAddress).balanceOf(habitatDiamond) / 100 * 1000; // 1000 is precision in case we want 1HBT - 1 votingPower; hbtAddress: 1000 in coefficients mapping
  }
}
