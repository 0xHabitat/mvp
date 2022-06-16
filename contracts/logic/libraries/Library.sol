// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IDiamondWritable } from '@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/base/DiamondBaseStorage.sol';
import { GovernanceStorage } from 'contracts/_library/ontap/governance/storage/GovernanceStorage.sol';
import { IUpgrade } from '../../external/IUpgrade.sol';

library Library {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  function _execute(uint256 _proposalId) internal returns (bool) {
    address upgrade = GovernanceStorage.layout().proposals[_proposalId].proposalContract;
    _upgrade(upgrade);
    // IGit(diamond).addUser() to repo's 'usedBy' store
    return true;
  }

  function _upgrade(address upgrade) internal {
    ( IDiamondWritable.FacetCut[] memory _cuts, address _target, bytes memory _data
    ) = IUpgrade(upgrade).get();
    _cut(_cuts, _target, _data);
    //TODO: consider emitting event of an upgrade -- emit Upgraded(address called, address by);
  }

  function _cut(
    IDiamondWritable.FacetCut[] memory _cuts, 
    address _target, 
    bytes memory _data
  ) internal {
    DiamondBaseStorage.layout().diamondCut(_cuts, _target, _data);
  }

}