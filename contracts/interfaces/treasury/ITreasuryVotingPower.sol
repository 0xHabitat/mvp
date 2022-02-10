// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasuryVotingPower {

  struct TreasuryVotingPower {
    address votingPowerManager;// StakeContract in general case and Setter of signers in a.k.a. multisig case
    mapping(address => uint) votingPower;
    // that address has voted. each proposal has deadline.
    uint totalAmountOfVotingPower; // if totalAmountOfVotes < minimumQuorum -> noone is able to create proposals
    uint minimumQuorum; // constructor parameter
    uint thresholdForProposal; // constructor parameter - percentage
    uint128 thresholdForInitiator; // constructor parameter - percentage
    uint128 precision; // constructor parameter e.g. 10000
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
