// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

contract TreasuryViewerFacet {
  // must be view - TODO make it view
  function getTreasuryDecisionType() external returns (IManagementSystem.DecisionType) {
    return LibManagementSystem._getDecisionType("treasury");
  }

  function getTreasuryProposalsCount() external returns (uint256) {
    return LibManagementSystem._getProposalsCount("treasury");
  }

  function getTreasuryActiveProposalsIds() external returns (uint256[] memory) {
    return LibManagementSystem._getActiveProposalsIds("treasury");
  }

  function getTreasuryAcceptedProposalsIds() external returns (uint256[] memory) {
    return LibManagementSystem._getAcceptedProposalsIds("treasury");
  }

  function getTreasuryProposal(uint256 proposalId)
    external
    returns (IProposal.Proposal memory)
  {
    return LibManagementSystem._getProposal("treasury", proposalId);
  }
}
