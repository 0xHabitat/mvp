// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasuryVotingPower {

  struct TreasuryVotingPower {
    address votingPowerManager;// StakeContract in general case and Setter of signers in a.k.a. multisig case
    mapping(address => uint) votingPower;
    uint totalAmountOfVotingPower; // if totalAmountOfVotes < minimumQuorum * maxTotalAmountOfVotingPower-> noone is able to create proposals
    uint maxAmountOfVotingPower; // init parameter
    uint64 minimumQuorum; // init parameter - percentage
    uint64 thresholdForProposal; // init parameter - percentage
    uint64 thresholdForInitiator; // init parameter - percentage
    uint64 precision; // init parameter e.g. 10000
  }
  // increasing voting power
  function increaseVotingPower(address voter, uint amount) external;

  // decreasing voting power
  function decreaseVotingPower(address voter, uint amount) external;

  function hasVotedInActiveProposals(address voter) external view returns(bool);

  // View functions
  function getVoterVotingPower(address voter) external view returns(uint);

  function getTotalAmountOfVotingPower() external view returns(uint);

  function getMinimumQuorum() external view returns(uint);

  function isQourum() external view returns(bool);

  function isEnoughVotingPower(address holder) external view returns(bool);

  function isProposalThresholdReached(uint amountOfVotes) external view returns(bool);
}
