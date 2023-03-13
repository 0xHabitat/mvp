// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryActions {
  /**
   * @notice Method creates treasury proposal.
   * @param destination Address to call.
   * @param value The amount of ETH is being sent.
   * @param callData Data payload (with selector) for a function from `destination` contract.
   * @return Newly created treasury proposal id.
   */
  function createTreasuryProposal(
    address destination,
    uint256 value,
    bytes memory callData
  ) external returns (uint256);

  /**
   * @notice Method creates several treasury proposals.
   * @param destinations An array of addresses to call.
   * @param values An array of ETH amounts are being sent.
   * @param callDatas An array of data payloads (with selector) for a functions from `destinations` contracts.
   * @return An array of newly created treasury proposal ids.
   */
  function createSeveralTreasuryProposals(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external returns (uint256[] memory);

  /**
   * @notice Allows to decide on treasury proposal.
   * @param proposalId The id of treasury proposal to decide on.
   * @param decision True - for proposal, false - against proposal.
   */
  function decideOnTreasuryProposal(uint256 proposalId, bool decision) external;

  /**
   * @notice Allows to decide on several treasury proposals.
   * @param proposalIds An array of treasury proposal ids to decide on.
   * @param decisions An array of booleans: True - for proposal, false - against proposal.
   */
  function decideOnSeveralTreasuryProposals(
    uint256[] calldata proposalIds,
    bool[] calldata decisions
  ) external;

  /**
   * @notice Allows to accept/reject treasury proposal.
   * @param proposalId The id of treasury proposal to accept/reject.
   */
  function acceptOrRejectTreasuryProposal(uint256 proposalId) external;

  /**
   * @notice Allows to accept/reject several treasury proposals.
   * @param proposalIds An array of treasury proposal ids to accept/reject.
   */
  function acceptOrRejectSeveralTreasuryProposals(uint256[] calldata proposalIds) external;

  /**
   * @notice Allows to execute treasury accepted proposal.
   * @param proposalId The id of treasury proposal to execute.
   * @return executionResult The proposal execution result, false if during execution call revert poped up.
   */
  function executeTreasuryProposal(uint256 proposalId) external returns (bool executionResult);

  /**
   * @notice Allows to execute several treasury accepted proposals.
   * @param proposalIds An array of treasury proposal ids to execute.
   * @return executionResults An array of the proposal execution results: false if during execution call revert poped up.
   */
  function executeSeveralTreasuryProposals(
    uint256[] memory proposalIds
  ) external returns (bool[] memory executionResults);

  /**
   * @notice Allows to init treasury proposal to send erc20 tokens.
   * @param token Address of erc20 token contract, which should be sent.
   * @param receiver Address, which should receive tokens.
   * @param amount Amount of tokens, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendERC20FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 amount
  ) external returns (uint256 proposalId);

  /**
   * @notice Allows to init treasury proposal to send ETH.
   * @param receiver Address, which should receive ETH.
   * @param value Amount of ETH, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendETHFromTreasuryInitProposal(
    address receiver,
    uint256 value
  ) external returns (uint256 proposalId);

  /**
   * @notice Allows to init treasury proposal to send erc721 tokens.
   * @param token Address of erc721 token contract, which should be sent.
   * @param receiver Address, which should receive token.
   * @param tokenId The id of erc721 token, which should be sent.
   * @return proposalId Newly created treasury proposal id.
   */
  function sendERC721FromTreasuryInitProposal(
    address token,
    address receiver,
    uint256 tokenId
  ) external returns (uint256 proposalId);

  /**
   * @notice Allows to create/accept/execute treasury proposal in one call.
   * @param destination Address to call from the DAO diamond.
   * @param value The amount of ETH is being sent.
   * @param callData Data payload (with selector) for a function from `destination` contract.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function batchedTreasuryProposalExecution(
    address destination,
    uint256 value,
    bytes memory callData
  ) external returns (bool result);

  /**
   * @notice Allows to create/accept/execute several treasury proposals in one call.
   * @param destinations An array of addresses to call.
   * @param values An array of ETH amounts are being sent.
   * @param callDatas An array of data payloads (with selector) for a functions from `destinations` contracts.
   * @return results The proposal execution result, false if during execution call revert poped up.
   */
  function batchedSeveralTreasuryProposalsExecution(
    address[] calldata destinations,
    uint256[] calldata values,
    bytes[] calldata callDatas
  ) external returns (bool[] memory results);

  /**
   * @notice Allows to create/accept/execute treasury proposal
   *         to send ERC20 tokens in one call.
   * @param token Address of erc20 token contract, which should be sent.
   * @param receiver Address, which should receive tokens.
   * @param amount Amount of tokens, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendERC20FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 amount
  ) external returns (bool result);

  /**
   * @notice Allows to create/accept/execute treasury proposal
   *         to send ETH in one call.
   * @param receiver Address, which should receive ETH.
   * @param value Amount of ETH, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendETHFromTreasuryBatchedExecution(
    address receiver,
    uint256 value
  ) external returns (bool result);

  /**
   * @notice Allows to create/accept/execute treasury proposal
   *         to send ERC721 tokens in one call.
   * @param token Address of erc721 token contract, which should be sent.
   * @param receiver Address, which should receive token.
   * @param tokenId The id of erc721 token, which should be sent.
   * @return result The proposal execution result, false if during execution call revert poped up.
   */
  function sendERC721FromTreasuryBatchedExecution(
    address token,
    address receiver,
    uint256 tokenId
  ) external returns (bool result);
}
