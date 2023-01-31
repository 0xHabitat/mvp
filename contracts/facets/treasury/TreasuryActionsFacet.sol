// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasuryActions} from "../../interfaces/treasury/ITreasuryActions.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";
import {IERC20} from "../../libraries/openzeppelin/IERC20.sol";
import {IERC721} from "../../libraries/openzeppelin/IERC721.sol";

contract TreasuryActionsFacet is ITreasuryActions {
  // TODO for MS: add addresses and add active -> adjust diamondCut not to cut facets that are active ms through governance
  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes memory callData
  ) public override returns (uint256 proposalId) {
    require(destination != address(this), "Not a treasury proposal.");
    proposalId = LibDecisionProcess.createProposal("treasury", destination, value, callData);
  }

  function decideOnTreasuryProposal(uint256 proposalId, bool decision) public override {
    LibDecisionProcess.decideOnProposal("treasury", proposalId, decision);
  }

  function acceptOrRejectTreasuryProposal(uint256 proposalId) public override {
    LibDecisionProcess.acceptOrRejectProposal("treasury", proposalId);
  }

  function executeTreasuryProposal(uint256 proposalId) public override returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeTreasuryProposal(uint256)")));
    result = LibDecisionProcess.executeProposalCall("treasury", proposalId, thisSelector);
  }

  // few wrappers

  function sendERC20FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 amount
  ) public override returns(uint256 proposalId) {
    require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough tokens in treasury.");
    bytes memory callData = abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount);
    proposalId = createTreasuryProposal(token, uint256(0), callData);
  }

  function sendETHFromTreasuryInitProposal(
    address receiver,
    uint256 value
  ) public override returns(uint256 proposalId) {
    require(address(this).balance >= value, "Not enoug ether in treasury");
    bytes memory callData;
    proposalId = createTreasuryProposal(receiver, value, callData);
  }

  function sendERC721FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 tokenId
  ) public override returns(uint256 proposalId) {
    require(IERC721(token).ownerOf(tokenId) == address(this), "Token does not belong to treasury.");
    bytes memory callData = abi.encodeWithSelector(IERC721.safeTransferFrom.selector, address(this), receiver, tokenId);
    proposalId = createTreasuryProposal(token, uint256(0), callData);
  }

  // batch for direct caller
  function batchedTreasuryProposalExecution(
    address destination,
    uint256 value,
    bytes memory callData
  ) public override returns(bool result) {
    uint256 proposalId = createTreasuryProposal(destination, value, callData);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  function sendERC20FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 amount
  ) public override returns(bool result) {
    uint256 proposalId = sendERC20FromTreasuryInitProposal(token, receiver, amount);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  function sendETHFromTreasuryBatchedExecution(
    address receiver,
    uint256 value
  ) public override returns(bool result) {
    uint256 proposalId = sendETHFromTreasuryInitProposal(receiver, value);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  function sendERC721FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 tokenId
  ) public override returns(bool result) {
    uint256 proposalId = sendERC721FromTreasuryInitProposal(token, receiver, tokenId);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  // MULTI PROPOSALS
  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external override returns (uint256[] memory) {
    uint256 numberOfProposals = destinations.length;
    require(
      values.length == numberOfProposals &&
        callDatas.length == numberOfProposals,
      "Different array length"
    );
    uint256[] memory proposalIds = new uint256[](numberOfProposals);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createTreasuryProposal(
        destinations[i],
        values[i],
        callDatas[i]
      );
    }
    return proposalIds;
  }

  function decideOnSeveralTreasuryProposals(uint256[] calldata proposalsIds, bool[] calldata decisions)
    external
    override
  {
    require(proposalsIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalsIds.length; i++) {
      decideOnTreasuryProposal(proposalsIds[i], decisions[i]);
    }
  }

  function acceptOrRejectSeveralTreasuryProposals(uint256[] calldata proposalIds) external override {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectTreasuryProposal(proposalIds[i]);
    }
  }

  function executeSeveralTreasuryProposals(uint256[] memory proposalIds) external override returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeTreasuryProposal(
        proposalIds[i]
      );
    }
  }

  function batchedSeveralTreasuryProposalsExecution(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) public override returns(bool[] memory results) {
    uint256 numberOfProposals = destinations.length;
    require(
      values.length == numberOfProposals &&
        callDatas.length == numberOfProposals,
      "Different array length"
    );
    results = new bool[](numberOfProposals);
    for (uint256 i = 0; i < numberOfProposals; i++) {
      results[i] = batchedTreasuryProposalExecution(
        destinations[i],
        values[i],
        callDatas[i]
      );
    }
  }
}
