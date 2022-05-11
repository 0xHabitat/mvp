// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/ISubDAO.sol";

library LibManagementSystem {
  /*
struct ManagementSystem {
  VotingSystem governanceVotingSystem;
  VotingSystem treasuryVotingSystem;
  VotingSystem subDAOCreationVotingSystem;
  address votingPowerManager;
  address governanceERC20Token;
  address[] governanceSigners;
  address[] treasurySigners;
  address[] subDAOCreationSigners;
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
    return ms.votingPowerManager;
  }

  function _getGovernanceERC20Token(bytes32 position) internal view returns (address) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      uint8(ms.governanceVotingSystem) == uint8(IManagementSystem.VotingSystem.ERC20PureVoting) ||
        uint8(ms.treasuryVotingSystem) == uint8(IManagementSystem.VotingSystem.ERC20PureVoting) ||
        uint8(ms.subDAOCreationVotingSystem) ==
        uint8(IManagementSystem.VotingSystem.ERC20PureVoting),
      "None of the management systems use ERC20PureVoting"
    );
    return ms.governanceERC20Token;
  }

  function _getGovernanceSigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.governanceVotingSystem == IManagementSystem.VotingSystem.Signers,
      "Governance voting system is not Signers."
    );
    return ms.governanceSigners;
  }

  function _getTreasurySigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.treasuryVotingSystem == IManagementSystem.VotingSystem.Signers,
      "Treasury voting system is not Signers."
    );
    return ms.treasurySigners;
  }

  function _getSubDAOCreationSigners(bytes32 position) internal view returns (address[] storage) {
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(position);
    require(
      ms.subDAOCreationVotingSystem == IManagementSystem.VotingSystem.Signers,
      "SubDAOCreation voting system is not Signers."
    );
    return ms.subDAOCreationSigners;
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
