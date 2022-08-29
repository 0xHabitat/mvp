// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/ISubDAO.sol";
import {LibDAOStorage} from "./LibDAOStorage.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

library LibManagementSystem {
  /*
  struct ManagementSystems {
    uint numberOfManagementSystems = 5;
    ManagementSystem setAddChangeManagementSystem;
    ManagementSystem governance;
    ManagementSystem treasury;
    ManagementSystem subDAOsCreation;
    ManagementSystem launchPad;
  }

  struct ManagementSystem {
    string nameMS;
    DecisionType decisionType;
    bytes32 dataPosition;
  }
*/
  function _getManagementSystems()
    internal
    view
    returns (IManagementSystem.ManagementSystems storage mss)
  {
    bytes32 position = LibDAOStorage._getManagementSystemsPosition();

    assembly {
      mss.slot := position
    }
  }

  function _getManagementSystem(string memory msName)
    internal
    view
    returns(IManagementSystem.ManagementSystem memory ms)
  {
    IManagementSystem.ManagementSystems storage mss = _getManagementSystems();
    bytes32 bName = keccak256(bytes(msName));
    if (bName == keccak256(bytes("setAddChangeManagementSystem"))) {
      ms = mss.setAddChangeManagementSystem;
    } else if (bName == keccak256(bytes("governance"))) {
      ms = mss.governance;
    } else if (bName == keccak256(bytes("treasury"))) {
      ms = mss.treasury;
    } else if (bName == keccak256(bytes("subDAOsCreation"))) {
      ms = mss.subDAOsCreation;
    } else if (bName == keccak256(bytes("launchPad"))) {
      ms = mss.launchPad;
    } else {
      if (mss.numberOfManagementSystems > 5) {
        // look for a name
        revert("not implemented yet");
      } else {
        revert("Mananagement system with input name does not exist.");
      }
    }
  }

  function _getMSData(bytes32 position) internal pure returns(IManagementSystem.MSData storage msData) {
    assembly {
      msData.slot := position
    }
  }

  function _getMSDataByName(string memory msName) internal view returns(IManagementSystem.MSData storage msData) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    msData = _getMSData(ms.dataPosition);
  }

  // viewers for specific ms
  function _getDecisionType(string memory msName) internal view returns(IManagementSystem.DecisionType) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    return ms.decisionType;
  }

  function _getProposal(string memory msName, uint proposalId) internal view returns(IProposal.Proposal memory proposal) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    proposal = msData.proposals[proposalId];
  }

  function _getActiveVotingProposalsIds(string memory msName) internal view returns(uint256[] memory) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.activeVotingProposalsIds;
  }

  function _getAcceptedProposalsIds(string storage msName) internal view returns(uint256[] storage) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.acceptedProposalsIds;
  }

  function _getProposalsCount(string memory msName) internal view returns(uint256) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.proposalsCounter;
  }


/*
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

  function _getManagementSystem(string memory msName)
    internal
    pure
    returns(IManagementSystem.ManagementSystem memory ms)
  {
    bytes32 position = LibDAOStorage._getManagementSystemsPosition(); // am i getting a number by this slot
    uint numberOfManagementSystems;
    assembly {
      numberOfManagementSystems := sload(position)
    }
    uint index;
    bool exist;
    uint pos = uint(position) + 1;
    for (uint i = 0; i < numberOfManagementSystems; i++) {
      string memory nameMS;
      assembly {
        nameMS := sload(add(pos, mul(i, 3)))
      }
      if (nameMS == msName) {
        exist = true;
        index = i;
      }
    }
    if (exist) {
      pos = pos + index * 3;
      assembly {
        ms.nameMS := sload(pos)
        ms.decisionType := sload(add(pos, 1))
        ms.dataPosition := sload(add(pos, 2))
      }
    } else {
      revert("Mananagement system with input name does not exist.");
    }
    // if yes than the idea is to go through the loop and sload position + 1, 2, 3,..n and find position name
    // after that just load decisionType and dataPosition

  }
  */
}
