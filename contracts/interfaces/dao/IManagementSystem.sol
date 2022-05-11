// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IManagementSystem {
  enum VotingSystem {
    VotingPowerManager, //stake contract
    ERC20PureVoting, // Compound
    Signers // Gnosis
    //BountyCreation - gardener, worker, reviewer - 3 signers
  }

  struct ManagementSystem {
    VotingSystem governanceVotingSystem;
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
    // VotingSystem bountyCreation;
    address votingPowerManager;
    address governanceERC20Token;
    address[] governanceSigners;
    address[] treasurySigners;
    address[] subDAOCreationSigners;
    //address[] signers; // maybe better use Gnosis data structure (nested array) instead of array
  }
}
