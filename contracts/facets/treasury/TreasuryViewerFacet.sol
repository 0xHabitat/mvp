// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// DEPRECATED
// TODO remove this facet and all usage in code
// Use instead general viewer facet for modules: ModuleViewerFacet
import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {LibManagementSystem} from "../../libraries/dao/LibManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

contract TreasuryViewerFacet {

  function getTreasuryDecisionType() external view returns (IManagementSystem.DecisionType) {
    return LibManagementSystem._getDecisionType("treasury");
  }

  function getTreasuryProposalsCount() external view returns (uint256) {
    return LibManagementSystem._getProposalsCount("treasury");
  }

  function getTreasuryActiveProposalsIds() external view returns (uint256[] memory) {
    return LibManagementSystem._getActiveProposalsIds("treasury");
  }

  function getTreasuryAcceptedProposalsIds() external view returns (uint256[] memory) {
    return LibManagementSystem._getAcceptedProposalsIds("treasury");
  }

  function getTreasuryProposal(uint256 proposalId)
    external
    view
    returns (IProposal.Proposal memory)
  {
    return LibManagementSystem._getProposal("treasury", proposalId);
  }
}
