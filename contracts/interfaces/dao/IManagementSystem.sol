// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IProposal} from "../IProposal.sol";

interface IManagementSystem {

  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20, // stake contract
    Signers // Gnosis
    //ERC20PureVoting, // Compound
    //BountyCreation - gardener, worker, reviewer - 3 signers
  }

  struct ManagementSystem {
    string nameMS; // very important that this item is bytes32, so the string is max 31 char
    DecisionType decisionType;
    address currentDecider; // TODO remember to adjust modifier to protect new storage slots
    bytes32 dataPosition;
  }

  struct ManagementSystems {
    uint numberOfManagementSystems;
    ManagementSystem setAddChangeManagementSystem;
    ManagementSystem governance;
    ManagementSystem treasury;
    ManagementSystem subDAOsCreation;
    ManagementSystem launchPad;
  }
  // this struct is stored at dataPosition slot
  struct MSData {
    // decisionSystem => data
    mapping(DecisionType => bytes) decisionSpecificData;
    // proposals
    //mapping(uint256 => bytes) proposals;
    mapping(uint256 => IProposal.Proposal) proposals;
    uint256[] activeProposalsIds;
    uint256[] acceptedProposalsIds;
    uint256 proposalsCounter;
  }
}
