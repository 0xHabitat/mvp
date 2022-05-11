// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasuryVotingPower {
  struct TreasuryVotingPower {
    uint64 minimumQuorum;
    uint64 thresholdForProposal;
    uint64 thresholdForInitiator;
    uint64 precision;
  }

  function minimumQuorumNumerator() external view returns (uint64);

  function thresholdForProposalNumerator() external view returns (uint64);

  function thresholdForInitiatorNumerator() external view returns (uint64);

  function treasuryDenominator() external view returns (uint64);

  function getMinimumQuorum() external view returns (uint256);

  function isQourum() external view returns (bool);

  function isEnoughVotingPower(address holder) external view returns (bool);

  function isProposalThresholdReached(uint256 amountOfVotes) external view returns (bool);
}
