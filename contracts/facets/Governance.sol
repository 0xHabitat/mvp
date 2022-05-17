// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20BaseStorage } from "@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol";
import { GovernanceStorage } from "contracts/storage/GovernanceStorage.sol"; 
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

/**
 * @notice contract forked from Nick Mudge's Governance-token-diamond: https://github.com/mudgen/governance-token-diamond
 */

contract Governance {
    using AddressUtils for address;
    using ERC20BaseStorage for ERC20BaseStorage.Layout;
    
    event Propose(address _proposer, address _proposalContract, uint _deadline);
    event Vote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);
    event UnVote(uint indexed _proposalId, address indexed _voter, uint _votes, bool _support);
    event ProposalExecutionSuccessful(uint _proposalId, bool _passed);
    event ProposalExecutionFailed(uint _proposalId, bytes _error);

    function proposalCount() external view returns (uint) {
        GovernanceStorage.Layout storage g = GovernanceStorage.layout();  
        return g.proposalCount;
    }

    function propose(address _proposalContract, uint _deadline) external returns (uint256 proposalId) {
        require(_proposalContract.isContract(), "Proposed contract has no code");
        ERC20BaseStorage.Layout storage ts = ERC20BaseStorage.layout();
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
        // access address mapping for diamantaire
        unchecked {
            require(_deadline > block.timestamp + (gs.minDuration * 3600), 'Governance: Voting duration must be longer');
            require(_deadline < block.timestamp + (gs.maxDuration * 3600), "Governance: Voting time must be shorter");
        }
    
        uint proposerBalance = ts.balances[msg.sender];
        uint totalSupply = ts.totalSupply;        
        require(proposerBalance >= (totalSupply / gs.proposalThresholdDivisor), "Governance: Balance less than proposer threshold");
        proposalId = gs.proposalCount++;
        GovernanceStorage.Proposal storage p = gs.proposals[proposalId];
        p.proposer = msg.sender;
        p.proposalContract = _proposalContract;
        p.deadline = uint64(_deadline);
        emit Propose(msg.sender, _proposalContract, _deadline);
        // adding vote
        p.votesYes = uint96(proposerBalance);
        p.voted[msg.sender] = GovernanceStorage.Voted(uint96(proposerBalance), true);
        gs.votedProposalIds[msg.sender].push(uint24(proposalId));
        emit Vote(proposalId, msg.sender, proposerBalance, true);
    }

    function executeProposal(uint256 _proposalId) external {
        ERC20BaseStorage.Layout storage ets = ERC20BaseStorage.layout();
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();   
        GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];
        address proposer = p.proposer;
        require(proposer != address(0), "Governance: Proposal does not exist");
        require(block.timestamp > p.deadline, "Governance: Voting has not ended");        
        require(p.executed != true, "Governance: Proposal has already been executed");
        p.executed = true;
        uint totalSupply = ets.totalSupply;
        uint forVotes = p.votesYes;
        uint againstVotes = p.votesNo;
        bool proposalPassed = forVotes > againstVotes && forVotes > ets.totalSupply / gs.quorumDivisor;
        uint votes = p.voted[proposer].votes;
        if(proposalPassed) {
            address proposalContract = p.proposalContract;
            uint contractSize;
            assembly { contractSize := extcodesize(proposalContract) }
            if(contractSize > 0) {
                (bool success, ) = proposalContract.delegatecall(
                    abi.encodeWithSignature("execute(uint256)",_proposalId)
                );
                if(success) {
                    uint fractionOfTotalSupply = totalSupply / gs.voteAwardCapDivisor;
                    if(votes > fractionOfTotalSupply) {
                        votes = fractionOfTotalSupply;
                    }
                    // 5 percent reward
                    uint proposerAwardDivisor = gs.proposerAwardDivisor;
                    ets.totalSupply += uint96(votes / proposerAwardDivisor);
                    ets.balances[proposer] += votes / proposerAwardDivisor;

                    emit ProposalExecutionSuccessful(_proposalId, true);
                    // and delete proposal?
                }
                else {
                    p.stuck = true;
                    p.executed = false;
                    emit ProposalExecutionFailed(_proposalId, bytes('Delegatecall failed'));                                
                }
            }
            else {
                p.stuck = true;
                p.executed = false;
                emit ProposalExecutionFailed(_proposalId, bytes('Proposal contract size is 0'));
            }
        }
        else {
            ets.balances[proposer] -= votes;
            emit ProposalExecutionSuccessful(_proposalId, false);
            // and delete proposal?
        }                
    }

    enum ProposalStatus { 
        NoProposal, // ___________________| 0 |
        PassedAndReadyForExecution, // ___| 1 |
        RejectedAndReadyForExecution, // _| 2 |
        PassedAndExecutionStuck, // ______| 3 |
        VotePending, // __________________| 4 |
        Passed, // _______________________| 5 |
        Rejected // ______________________| 6 |
    }

    function proposalStatus(uint256 _proposalId) public view returns (ProposalStatus status) {
        ERC20BaseStorage.Layout storage ets = ERC20BaseStorage.layout();
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
        GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];
        uint deadline = p.deadline;
        if(deadline == 0) {
            status = ProposalStatus.NoProposal;
        }
        else if(block.timestamp < deadline) {
            status = ProposalStatus.VotePending;
        }
        else if(p.stuck) {
            status = ProposalStatus.PassedAndExecutionStuck;
        }
        else {
            uint forVotes = p.votesYes;
            bool passed = forVotes > p.votesNo && forVotes > ets.totalSupply / gs.quorumDivisor;
            if(p.executed) {
                if(passed) {
                    status = ProposalStatus.Passed;
                }
                else {
                    status = ProposalStatus.Rejected;
                }
            }
            else {
                if(passed) {
                    status = ProposalStatus.PassedAndReadyForExecution;
                }
                else {
                    status = ProposalStatus.RejectedAndReadyForExecution;
                }
            }
        }
    }
    
    struct RetrievedProposal {
        address proposalContract;
        address proposer;
        uint64 deadline;                
        uint96 againstVotes;
        uint96 forVotes;
        ProposalStatus status;
    }

    function proposal(uint256 _proposalId) external view returns (RetrievedProposal memory retrievedProposal) {
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();   
        GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];
        retrievedProposal = RetrievedProposal({
            proposalContract: p.proposalContract,
            proposer: p.proposer,
            deadline: p.deadline,                   
            againstVotes: p.votesNo,
            forVotes: p.votesYes,
            status: proposalStatus(_proposalId)
        });        
    }

    function vote(uint256 _proposalId, bool _support) external {
        ERC20BaseStorage.Layout storage ets = ERC20BaseStorage.layout();
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();   
        require(_proposalId < gs.proposalCount, "Governance: _proposalId does not exist");
        GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];
        require(block.timestamp < p.deadline, "Governance: Voting ended");
        require(p.voted[msg.sender].votes == 0, "Governance: Already voted");        
        uint balance = ets.balances[msg.sender];
        if(_support) {
            p.votesYes += uint96(balance);
        }
        else {
            p.votesNo += uint96(balance);
        }
        p.voted[msg.sender] = GovernanceStorage.Voted(uint96(balance), _support);
        gs.votedProposalIds[msg.sender].push(uint24(_proposalId));
        emit Vote(_proposalId, msg.sender, balance, _support);

        // Reward voter with increase in token            
        uint fractionOfTotalSupply = ets.totalSupply / gs.voteAwardCapDivisor;
        if(balance > fractionOfTotalSupply) {
            balance = fractionOfTotalSupply;
        }
        uint voterAwardDivisor = gs.voterAwardDivisor;
        ets.totalSupply += uint96(balance / voterAwardDivisor);
        ets.balances[msg.sender] += balance / voterAwardDivisor;
    }

    function unvote(uint256 _proposalId) external {
        ERC20BaseStorage.Layout storage ets = ERC20BaseStorage.layout();
        GovernanceStorage.Layout storage gs = GovernanceStorage.layout();   
        require(_proposalId < gs.proposalCount, "Governance: _proposalId does not exist");
        GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];
        require(block.timestamp < p.deadline, "Governance: Voting ended"); 
        require(p.proposer != msg.sender, "Governance: Cannot unvote your own proposal");       
        uint votes = p.voted[msg.sender].votes;
        bool support = p.voted[msg.sender].support;
        require(votes > 0, "Governance: Did not vote");                
        if(support) {
            p.votesYes -= uint96(votes);
        }
        else {
            p.votesNo -= uint96(votes);
        }
        delete p.voted[msg.sender];
        uint24[] storage proposalIds = gs.votedProposalIds[msg.sender];
        uint length = proposalIds.length;
        uint index;
        for(; index < length; index++) {
            if(uint(proposalIds[index]) == _proposalId) {
                break;
            }
        }
        uint lastIndex = length-1;
        if(lastIndex != index) {
            proposalIds[index] = proposalIds[lastIndex];    
        }
        proposalIds.pop();
        emit UnVote(_proposalId, msg.sender, votes, support);
        // Remove voter reward
        uint voterAwardDivisor = gs.voterAwardDivisor;
        ets.totalSupply -= uint96(votes / voterAwardDivisor);
        ets.balances[msg.sender] -= votes / voterAwardDivisor;
    }

}