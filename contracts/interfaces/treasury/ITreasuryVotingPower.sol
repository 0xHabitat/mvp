// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasuryVotingPower {

  struct TreasuryVotingPower {
    address votingPowerManager;
    mapping(address => uint) votingPower;
    uint totalAmountOfVotingPower;
    uint maxAmountOfVotingPower;
    uint64 minimumQuorum;
    uint64 thresholdForProposal;
    uint64 thresholdForInitiator;
    uint64 precision;
  }
  // increasing voting power
  function increaseVotingPower(address voter, uint amount) external;

  // decreasing voting power
  function decreaseVotingPower(address voter, uint amount) external;

  function hasVotedInActiveProposals(address voter) external view returns(bool);

  // View functions
  function getTreasuryVotingPowerManager() external view returns(address);

  function getVoterVotingPower(address voter) external view returns(uint);

  function getTotalAmountOfVotingPower() external view returns(uint);

  function getMaxAmountOfVotingPower() external view returns(uint);

  function minimumQuorumNumerator() external view returns(uint64);

  function thresholdForProposalNumerator() external view returns(uint64);

  function thresholdForInitiatorNumerator() external view returns(uint64);

  function denominator() external view returns(uint64);

  function getMinimumQuorum() external view returns(uint);

  function isQourum() external view returns(bool);

  function isEnoughVotingPower(address holder) external view returns(bool);

  function isProposalThresholdReached(uint amountOfVotes) external view returns(bool);

}
