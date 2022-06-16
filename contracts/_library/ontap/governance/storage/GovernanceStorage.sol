// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library GovernanceStorage {

    ///@dev in order to use the upgrade system, Governance storage must implement a proposalId w/ a proposalContract

    struct Voted {        
        uint96 votes;
        bool support;
    }

    struct Proposal {
        // mapping(address => bool) support;
        // mapping(address => uint96) votes;
        mapping(address => Voted) voted;

        address proposalContract;
        string name;

        address proposer;
        bool executed;
        bool stuck;

        //proposal voting
        // mapping(address => bool) voted;
        bool votingStarted;
        uint64 deadline;
        uint96 votesYes;
        uint96 votesNo;
    }
    
    struct Layout {
        // Proposer must own enough tokens to submit a proposal
        uint8 proposalThresholdDivisor;
        // Require an amount of governance tokens for votes to pass a proposal
        uint8 quorumDivisor;
        // Proposers get an additional amount of tokens if proposal passes
        uint8 proposerAwardDivisor; 
        // Voters get an additional amount of tokens for voting on a proposal
        uint8 voterAwardDivisor; 
        // Cap voter and proposer token awards.
        // This is to help prevent too much inflation
        uint8 voteAwardCapDivisor;
        // max time (hours) a proposal can be voted on.
        uint16 maxDuration;
        uint16 minDuration;
        uint24 proposalCount;
        mapping(uint => Proposal) proposals;
        mapping(address => uint24[]) votedProposalIds;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('ontap.governace.diamond.storage');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
