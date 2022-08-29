// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

contract TreasuryViewerFacet {
  function getTreasuryDecisionType() external returns (IManagementSystem.DecisionType) {
    return LibManagementSystem._getDecisionType("treasury");
  }

  function getTreasuryProposalsCount() external returns (uint256) {
    return LibManagementSystem._getProposalsCount("treasury");
  }

  function getTreasuryActiveVotingProposalsIds() external returns (uint256[] memory) {
    return LibManagementSystem._getActiveVotingProposalsIds("treasury");
  }

  function getTreasuryProposal(uint256 proposalId)
    external
    returns (IProposal.Proposal memory)
  {
    return LibManagementSystem._getProposal("treasury", proposalId);
  }
}
