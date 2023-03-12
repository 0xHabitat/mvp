// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IProposal} from "../IProposal.sol";

interface IManagementSystem {
  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20,
    Signers
    //ERC20PureVoting,
    //BountyCreation - gardener, worker, reviewer - 3 signers
  }

  /// @dev nameMS is bytes32, so the string must be max 31 char
  struct ManagementSystem {
    string nameMS;
    DecisionType decisionType;
    bytes32 dataPosition;
    address currentDecider;
  }

  /// @dev MSData struct is stored at dataPosition slot
  /// @dev maybe think about proposals protection
  struct MSData {
    mapping(DecisionType => bytes) decisionSpecificData;
    mapping(uint256 => IProposal.Proposal) proposals;
    uint256[] activeProposalsIds;
    uint256[] acceptedProposalsIds;
    uint256 proposalsCounter;
  }
}
