// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {LibDAOStorage} from "./libraries/dao/LibDAOStorage.sol";
import {IDAO} from "./interfaces/dao/IDAO.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "./interfaces/IAddressesProvider.sol";
import {IManagementSystem} from "./interfaces/dao/IManagementSystem.sol";
import {IUniswapV2Factory} from "./interfaces/token/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/token/IUniswapV2Pair.sol";
import {IWETH} from "./interfaces/token/IWETH.sol";
import {IERC20} from "./libraries/openzeppelin/IERC20.sol";

enum ETHPair {
  None,
  UniV2,
  Sushi,
  UniPlusSushi
}

struct VPMToken {
  uint coefficient;
  //uint price
}

struct Token {
  string tokenName;
}

struct VPMTokens {
  VPMToken nativeGovernanceToken;
  VPMToken uniDerivative;
  VPMToken sushiDerivative;
}

struct DAOMeta {
  string daoName;
  string purpose;
  string info;
  string socials;
}

contract HabitatDiamondFactory {

  function deployHabitatDiamond(
    address addressesProvider,
    IManagementSystem.VotingSystems memory _vs,
    IManagementSystem.Signers memory _s,
    bytes memory habitatDiamondConstructorArgs,
    ETHPair ethPair
  ) external payable returns(address habitatDiamond) {
    // deploy HabitatDiamond with all set up from params
    // first param contractOwner - setting Factory as contractOwner and at the end of call move ownership to msg.sender -> later need to adjust replacing ownership logic to voting logic (a.k.a. Diamond is owner of itself)
    //bytes memory habitatDiamondConstructorArgs = abi.encode(address(this), addressesProvider,ethPair,);
    bytes memory bytecode = bytes.concat(type(HabitatDiamond).creationCode, habitatDiamondConstructorArgs);
    assembly {
      habitatDiamond := create(0, add(bytecode, 32), mload(bytecode))
    }
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

contract HabitatDiamond {
  constructor(
    address _contractOwner,//???
    address addressesProvider,
    DAOMeta memory daoMetaData,
    IManagementSystem.VotingSystems memory _vs,
    IManagementSystem.Signers memory _s,
    Token memory t,
    ETHPair ethPair
  ) payable {

    LibDiamond.setContractOwner(_contractOwner); //???
    //???
    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    IAddressesProvider.Facet memory diamondCutFacet = IAddressesProvider(addressesProvider).getDiamondCutFacet();
    cut[0] = IDiamondCut.FacetCut({
      facetAddress: diamondCutFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: diamondCutFacet.functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
    //???
    // DAO first
    IDAO.DAOStorage storage daoStruct = LibDAOStorage.daoStorage();
    daoStruct.daoName = daoMetaData.daoName;
    daoStruct.purpose = daoMetaData.purpose;
    daoStruct.info = daoMetaData.info;
    daoStruct.socials = daoMetaData.socials;
    daoStruct.managementSystemPosition = keccak256(bytes.concat(bytes(daoMetaData.daoName), bytes(daoMetaData.purpose), bytes(daoMetaData.info), bytes(daoMetaData.socials)));

    // Token second

    // Management section
    if (_vs.governanceVotingSystem == IManagementSystem.VotingSystem.VotingPowerManagerERC20) {
      // deploy vpm and set the state for
      // do as internal func
      // check if already setted
      address votingPowerInit = IAddressesProvider(addressesProvider).getVotingPowerInit();

      //LibDiamond.initializeDiamondCut(votingPowerInit, calldata);
      //uint256 _maxAmountOfVotingPower,
      //uint256 _stakeContrPrecision,
      //address[] memory _governanceTokens,
      //uint256[] memory _coefficients


    } else if (_vs.governanceVotingSystem == IManagementSystem.VotingSystem.Signers) {
      // work with signers
    }
/*
    // Add the diamondCut external function from the diamondCutFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = IDiamondCut.FacetCut({
      facetAddress: _diamondCutFacet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
    // i guess we can use this one to initialize state without facets if needed
    LibDiamond.initializeDiamondCut(initAddress, calldata);
*/
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    // get diamond storage
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = address(bytes20(ds.facets[msg.sig]));
    require(facet != address(0), "Diamond: Function does not exist");
    // Execute external function from facet using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}
