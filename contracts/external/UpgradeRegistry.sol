// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";
import { DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol";
import { MinimalProxyFactory } from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import { GovernanceStorage } from "contracts/storage/GovernanceStorage.sol";
import { IUpgradeRegistry } from "contracts/interfaces/IUpgradeRegistry.sol";

import { RepositoryStorage } from "contracts/storage/RepositoryStorage.sol";
import { SafeOwnable, OwnableStorage } from "@solidstate/contracts/access/SafeOwnable.sol";

import 'hardhat/console.sol';

contract UpgradeRegistry is MinimalProxyFactory, SafeOwnable {
  
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;
  using OwnableStorage for OwnableStorage.Layout;
  using RepositoryStorage for RepositoryStorage.Layout;

  event UpgradeRegistered (
    address owner,
    address upgrade, 
    IDiamondCuttable.FacetCut[] facetCuts, 
    address target, 
    bytes data
  );

  bool private registered;

  struct Cut {
    address target;
    IDiamondCuttable.FacetCutAction action;
    bytes4[] selectors;
  }

  Cut[] public cuts;
  address public target;
  bytes public data;

  function register(
    IDiamondCuttable.FacetCut[] memory _facetCuts, 
    address _target, 
    bytes calldata _data) 
  external returns (address) {
    address _upgrade = _deployMinimalProxy(address(this));
    IUpgradeRegistry(_upgrade).set(msg.sender, _facetCuts, _target, _data);
    emit UpgradeRegistered(msg.sender, _upgrade, _facetCuts, _target, _data);
    return _upgrade;
  }

  function set(
    address _owner,
    IDiamondCuttable.FacetCut[] memory _facetCuts, 
    address _target, 
    bytes calldata _data) 
  external {
    require(!registered, 
    "UpgradeProposalRegistry: Upgrade already registered, you cannot change its state");
    // set owner (owner must accept ownership by calling this upgrade addr with "acceptOwnership()")
    OwnableStorage.layout().setOwner(_owner);
    //store cut
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      cuts.push(Cut(facetCut.target, facetCut.action, facetCut.selectors));
    }
    target = _target;
    data = _data;
    registered = true;
  }

  function get() 
  external view returns (IDiamondCuttable.FacetCut[] memory, address, bytes memory) {
    uint length = cuts.length;
    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](length);
    for (uint i; i < facetCuts.length; i++) {
      facetCuts[i] = IDiamondCuttable.FacetCut({
          target: cuts[i].target, 
          action: cuts[i].action,
          selectors: cuts[i].selectors
      });
    }
    return(facetCuts, target, data);
  }

  function execute(uint256 _proposalId) external {
    GovernanceStorage.Proposal storage p = GovernanceStorage.layout().proposals[_proposalId];

    address upgrade = p.proposalContract;
    require(RepositoryStorage._hasUpgrade(upgrade), "Repo must contain upgrade");

    (IDiamondCuttable.FacetCut[] memory facetCuts, address __target, bytes memory __data) = 
    IUpgradeRegistry(upgrade).get();

    DiamondBaseStorage.layout().diamondCut(facetCuts, __target, __data);
  }
}