// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDecisionProcess} from "../libraries/decisionSystem/LibDecisionProcess.sol";

contract PeaceTokenDistributorFacetTest  {

  address immutable peace;

  constructor(address _peace) {
    peace = _peace;
  }

  function createPeaceDistributionProposal(
    address[] memory receivers,
    uint256[] memory amounts
  ) public returns (uint256 proposalId) {
    bytes4 mintPeaceSelector = bytes4(keccak256(bytes("mintPeaceMax500(address[],uint256[])")));
    bytes memory callData = abi.encodeWithSelector(mintPeaceSelector, receivers, amounts);
    proposalId = LibDecisionProcess.createProposal("PeaceTokenDistributor", peace, 0, callData);
  }

  function decideOnPeaceDistributionProposal(uint256 proposalId, bool decision) public {
    LibDecisionProcess.decideOnProposal("PeaceTokenDistributor", proposalId, decision);
  }

  function acceptOrRejectPeaceDistributionProposal(uint256 proposalId) public {
    LibDecisionProcess.acceptOrRejectProposal("PeaceTokenDistributor", proposalId);
  }

  function executePeaceDistributionProposal(uint256 proposalId) public returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executePeaceDistributionProposal(uint256)")));
    result = LibDecisionProcess.executeProposalCall("PeaceTokenDistributor", proposalId, thisSelector);
  }

  function peaceDistributionBatchedExecution(
    address[] memory receivers,
    uint256[] memory amounts
  ) external returns(bool result) {
    uint256 proposalId = createPeaceDistributionProposal(receivers, amounts);
    acceptOrRejectPeaceDistributionProposal(proposalId);
    result = executePeaceDistributionProposal(proposalId);
  }
}
