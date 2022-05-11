// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IManagementSystem {
  enum VotingSystem {
    None,
    VotingPowerManagerERC20, //stake contract
    Signers // Gnosis
    // ERC20PureVoting // Compound
    // ElectedSignersByVPManager
    // VotingPowerManagerERC721
    // VotingPowerManagerERC1155
    // BountyCreation - gardener, worker, reviewer - 3 signers
  }

  struct ManagementSystem {
    VotingSystem governanceVotingSystem; // diamondCut
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
    //VotingSystem changeManagementSystem;
    // bool VPMERC20 used; ???
    // VotingSystem bountyCreation;
    bytes32 managementDataPosition; // or bytes managementData
  }

  struct ManagementData {
    address votingPowerManager;
    //address governanceERC20Token;
    address[] governanceSigners;
    address[] treasurySigners;
    address[] subDAOCreationSigners;
    //address[] signers; // maybe better use Gnosis data structure (nested array) instead of array
  }

  struct Signers {
    address[] governanceSigners;
    address[] treasurySigners;
    address[] subDAOCreationSigners;
  }

  struct VotingSystems {
    VotingSystem governanceVotingSystem;
    VotingSystem treasuryVotingSystem;
    VotingSystem subDAOCreationVotingSystem;
  }

}
