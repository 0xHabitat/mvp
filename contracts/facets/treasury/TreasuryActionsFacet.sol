// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITreasuryActions} from "../../interfaces/treasury/ITreasuryActions.sol";
import {LibDecisionProcess} from "../../libraries/decisionSystem/LibDecisionProcess.sol";
import {IERC20} from "../../libraries/openzeppelin/IERC20.sol";
import {IERC721} from "../../libraries/openzeppelin/IERC721.sol";

/**
 * @title TreasuryActionsFacet - Facet provides functions that handles interactions
 *                         with the DAO treasury module.
 * @notice Treasury module allows to make arbitrary calls (only call opcode)
 *         from the DAO diamond contract.
 * @author @roleengineer
 */
contract TreasuryActionsFacet is ITreasuryActions {

  /**
   * @notice Method creates treasury proposal.
   * @param destination Address to call from the DAO diamond.
   * @param value The amount of ETH is being sent.
   * @param callData Data payload (with selector) for a function from `destination` contract.
   * @return proposalId Newly created treasury proposal id.
   */
  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes memory callData
  ) public override returns (uint256 proposalId) {
    require(destination != address(this), "Not a treasury proposal.");
    proposalId = LibDecisionProcess.createProposal("treasury", destination, value, callData);
  }

  /**
   * @notice Allows to decide on treasury proposal.
   * @param proposalId The id of treasury proposal to decide on.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnTreasuryProposal(uint256 proposalId, bool decision) public override {
    LibDecisionProcess.decideOnProposal("treasury", proposalId, decision);
  }

  /**
   * @notice Allows to accept/reject treasury proposal. Should be called when
   *         decision considered to be done based on rules of treasury current decision type.
   * @param proposalId The id of treasury proposal to accept/reject.
   */
  function acceptOrRejectTreasuryProposal(uint256 proposalId) public override {
    LibDecisionProcess.acceptOrRejectProposal("treasury", proposalId);
  }

  /**
   * @notice Allows to execute treasury accepted proposal. Should be called at/after
   *         proposal execution timestamp.
   * @param proposalId The id of treasury proposal to execute.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function executeTreasuryProposal(uint256 proposalId) public override returns (bool result) {
    bytes4 thisSelector = bytes4(keccak256(bytes("executeTreasuryProposal(uint256)")));
    result = LibDecisionProcess.executeProposalCall("treasury", proposalId, thisSelector);
  }

  /*//////////////////////////////////////////////////////////////
                    WRAPPER FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows to init treasury proposal to send erc20 tokens from DAO diamond contract.
   * @param token Address of erc20 token contract, which should be sent.
   * @param receiver Address, which should receive tokens.
   * @param amount Amount of tokens, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendERC20FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 amount
  ) public override returns (uint256 proposalId) {
    require(IERC20(token).balanceOf(address(this)) >= amount, "Not enough tokens in treasury.");
    bytes memory callData = abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount);
    proposalId = createTreasuryProposal(token, uint256(0), callData);
  }

  /**
   * @notice Allows to init treasury proposal to send ETH from DAO diamond contract.
   * @param receiver Address, which should receive ETH.
   * @param value Amount of ETH, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendETHFromTreasuryInitProposal(
    address receiver,
    uint256 value
  ) public override returns (uint256 proposalId) {
    require(address(this).balance >= value, "Not enoug ether in treasury");
    bytes memory callData;
    proposalId = createTreasuryProposal(receiver, value, callData);
  }

  /**
   * @notice Allows to init treasury proposal to send erc721 tokens from DAO diamond contract.
   * @param token Address of erc721 token contract, which should be sent.
   * @param receiver Address, which should receive token.
   * @param tokenId The id of erc721 token, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendERC721FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 tokenId
  ) public override returns (uint256 proposalId) {
    require(IERC721(token).ownerOf(tokenId) == address(this), "Token does not belong to treasury.");
    bytes memory callData = abi.encodeWithSelector(
      IERC721.safeTransferFrom.selector,
      address(this),
      receiver,
      tokenId
    );
    proposalId = createTreasuryProposal(token, uint256(0), callData);
  }

  /*//////////////////////////////////////////////////////////////
                BATCHED FUNCTIONS FOR DIRECT CALLER
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Allows direct caller to create/accept/execute treasury proposal in one call.
   * @param destination Address to call from the DAO diamond.
   * @param value The amount of ETH is being sent.
   * @param callData Data payload (with selector) for a function from `destination` contract.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function batchedTreasuryProposalExecution(
    address destination,
    uint256 value,
    bytes memory callData
  ) public override returns (bool result) {
    uint256 proposalId = createTreasuryProposal(destination, value, callData);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute treasury proposal
   *         to send ERC20 tokens from DAO diamond contract in one call.
   * @param token Address of erc20 token contract, which should be sent.
   * @param receiver Address, which should receive tokens.
   * @param amount Amount of tokens, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendERC20FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 amount
  ) public override returns (bool result) {
    uint256 proposalId = sendERC20FromTreasuryInitProposal(token, receiver, amount);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute treasury proposal
   *         to send ETH from DAO diamond contract in one call.
   * @param receiver Address, which should receive ETH.
   * @param value Amount of ETH, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendETHFromTreasuryBatchedExecution(
    address receiver,
    uint256 value
  ) public override returns (bool result) {
    uint256 proposalId = sendETHFromTreasuryInitProposal(receiver, value);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  /**
   * @notice Allows direct caller to create/accept/execute treasury proposal
   *         to send ERC721 tokens from DAO diamond contract in one call.
   * @param token Address of erc721 token contract, which should be sent.
   * @param receiver Address, which should receive token.
   * @param tokenId The id of erc721 token, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendERC721FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 tokenId
  ) public override returns (bool result) {
    uint256 proposalId = sendERC721FromTreasuryInitProposal(token, receiver, tokenId);
    acceptOrRejectTreasuryProposal(proposalId);
    result = executeTreasuryProposal(proposalId);
  }

  /*//////////////////////////////////////////////////////////////
                    MULTI PROPOSALS FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Method creates several treasury proposals.
   * @param destinations An array of addresses to call from the DAO diamond.
   * @param values An array of ETH amounts are being sent.
   * @param callDatas An array of data payloads (with selector) for a functions from `destinations` contracts.
   * @return An array of newly created treasury proposal ids.
   */
  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external override returns (uint256[] memory) {
    uint256 numberOfProposals = destinations.length;
    require(
      values.length == numberOfProposals && callDatas.length == numberOfProposals,
      "Different array length"
    );
    uint256[] memory proposalIds = new uint256[](numberOfProposals);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalIds[i] = createTreasuryProposal(destinations[i], values[i], callDatas[i]);
    }
    return proposalIds;
  }

  /**
   * @notice Allows to decide on several treasury proposals.
   * @param proposalIds An array of treasury proposal ids to decide on.
   * @param decisions An array of booleans: True - for proposal, false - against proposal.
   */
  function decideOnSeveralTreasuryProposals(
    uint256[] calldata proposalIds,
    bool[] calldata decisions
  ) external override {
    require(proposalIds.length == decisions.length, "Different array length");
    for (uint256 i = 0; i < proposalIds.length; i++) {
      decideOnTreasuryProposal(proposalIds[i], decisions[i]);
    }
  }

  /**
   * @notice Allows to accept/reject several treasury proposals. Should be called when
   *         decisions considered to be done based on rules of treasury current decision type.
   * @param proposalIds An array of treasury proposal ids to accept/reject.
   */
  function acceptOrRejectSeveralTreasuryProposals(
    uint256[] calldata proposalIds
  ) external override {
    for (uint256 i = 0; i < proposalIds.length; i++) {
      acceptOrRejectTreasuryProposal(proposalIds[i]);
    }
  }

  /**
   * @notice Allows to execute several treasury accepted proposals. Should be
   *         called at/after proposals execution timestamp.
   * @param proposalIds An array of treasury proposal ids to execute.
   * @return results An array of the proposal execution results: false if during execution call revert poped up.
   */
  function executeSeveralTreasuryProposals(
    uint256[] memory proposalIds
  ) external override returns (bool[] memory results) {
    results = new bool[](proposalIds.length);
    for (uint256 i = 0; i < proposalIds.length; i++) {
      results[i] = executeTreasuryProposal(proposalIds[i]);
    }
  }

  /**
   * @notice Allows direct caller to create/accept/execute several treasury proposals in one call.
   * @param destinations An array of addresses to call from the DAO diamond.
   * @param values An array of ETH amounts are being sent.
   * @param callDatas An array of data payloads (with selector) for a functions from `destinations` contracts.
   * @return results The proposal execution result, false if during execution call revert poped up.
   */
  function batchedSeveralTreasuryProposalsExecution(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) public override returns (bool[] memory results) {
    uint256 numberOfProposals = destinations.length;
    require(
      values.length == numberOfProposals && callDatas.length == numberOfProposals,
      "Different array length"
    );
    results = new bool[](numberOfProposals);
    for (uint256 i = 0; i < numberOfProposals; i++) {
      results[i] = batchedTreasuryProposalExecution(destinations[i], values[i], callDatas[i]);
    }
  }
}
