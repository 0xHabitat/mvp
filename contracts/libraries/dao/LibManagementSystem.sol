// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";

library LibManagementSystem {
  /*
  struct ManagementSystem {
    VotingSystem governanceVotingSystem;
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
    VotingSystem changeManagementSystem;
    // VotingSystem bountyCreation;
    bytes32 managementDataPosition;
  }

  struct ManagementData {
    address votingPowerManager;
    address[] governanceSigners;
    address[] treasurySigners;
    address[] subDAOCreationSigners;
    //address governanceERC20Token;
    //address[] signers; // maybe better use Gnosis data structure (nested array) instead of array
  }
*/
  function _getManagementSystemByPosition(bytes32 position)
    internal
    pure
    returns (IManagementSystem.ManagementSystem storage ms)
  {
    assembly {
      ms.slot := position
    }
  }

  function _getManagementDataByPosition(bytes32 position)
    internal
    pure
    returns (IManagementSystem.ManagementData storage md)
  {
    assembly {
      md.slot := position
    }
  }

  function _getGovernanceVotingSystem(bytes32 position)
    internal
    view
    returns (IManagementSystem.VotingSystem gvs)
  {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    gvs = ms.governanceVotingSystem;
  }

  function _getTreasuryVotingSystem(bytes32 position)
    internal
    view
    returns (IManagementSystem.VotingSystem tvs)
  {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    tvs = ms.treasuryVotingSystem;
  }

  function _getSubDAOCreationVotingSystem(bytes32 position)
    internal
    view
    returns (IManagementSystem.VotingSystem sdcvs)
  {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    sdcvs = ms.subDAOCreationVotingSystem;
  }

  function _getVotingPowerManager(bytes32 position) internal view returns (address) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      uint8(ms.governanceVotingSystem) == uint8(0) ||
        uint8(ms.treasuryVotingSystem) == uint8(0) ||
        uint8(ms.subDAOCreationVotingSystem) == uint8(0),
      "None of the management systems use votingPowerManager"
    );
    IManagementSystem.ManagementData storage md = _getManagementDataByPosition(ms.managementDataPosition);
    return md.votingPowerManager;
  }

  function _getGovernanceSigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.governanceVotingSystem == IManagementSystem.VotingSystem.Signers,
      "Governance voting system is not Signers."
    );
    IManagementSystem.ManagementData storage md = _getManagementDataByPosition(ms.managementDataPosition);
    return md.governanceSigners;
  }

  function _getTreasurySigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.treasuryVotingSystem == IManagementSystem.VotingSystem.Signers,
      "Treasury voting system is not Signers."
    );
    IManagementSystem.ManagementData storage md = _getManagementDataByPosition(ms.managementDataPosition);
    return md.treasurySigners;
  }

  function _getSubDAOCreationSigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.subDAOCreationVotingSystem == IManagementSystem.VotingSystem.Signers,
      "SubDAOCreation voting system is not Signers."
    );
    IManagementSystem.ManagementData storage md = _getManagementDataByPosition(ms.managementDataPosition);
    return md.subDAOCreationSigners;
  }

  function _isGovernanceSigner(bytes32 position, address _signer) internal view returns (bool) {
    address[] storage govSigners = _getGovernanceSigners(position);
    // maybe better use Gnosis data structure (nested array) instead of an array
    for (uint256 i = 0; i < govSigners.length; i++) {
      if (govSigners[i] == _signer) {
        return true;
      }
    }
    return false;
  }

  function _isTreasurySigner(bytes32 position, address _signer) internal view returns (bool) {
    address[] storage treasurySigners = _getTreasurySigners(position);
    // maybe better use Gnosis data structure (nested array) instead of an array
    for (uint256 i = 0; i < treasurySigners.length; i++) {
      if (treasurySigners[i] == _signer) {
        return true;
      }
    }
    return false;
  }

  function _isSubDAOCreationSigner(bytes32 position, address _signer) internal view returns (bool) {
    address[] storage sdcSigners = _getSubDAOCreationSigners(position);
    // maybe better use Gnosis data structure (nested array) instead of an array
    for (uint256 i = 0; i < sdcSigners.length; i++) {
      if (sdcSigners[i] == _signer) {
        return true;
      }
    }
    return false;
  }
}
