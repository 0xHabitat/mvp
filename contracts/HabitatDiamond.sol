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

contract HabitatDiamond {
  constructor(
    address _contractOwner,//???
    address addressesProvider,
    DAOMeta memory daoMetaData,
    IManagementSystem.VotingSystems memory _vs
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
