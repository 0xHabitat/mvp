/*
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { ITreasuryExecution } from "../../interfaces/treasury/ITreasuryExecution.sol";
import { ITreasury } from "../../interfaces/treasury/ITreasury.sol";
import { LibTreasury } from "../../libraries/LibTreasury.sol";
import { SubDAOInit } from "../../upgradeInitializers/SubDAOInit.sol";
import { LibDAOStorage } from "../../libraries/LibDAOStorage.sol";
import { LibSubDAO } from "../../libraries/LibSubDAO.sol";

contract SubDAOExecutionFacet is ISubDAOExecution {

  function executeSubDAOProposal(uint proposalId) external override returns(bool result) {
    // the end of the function after proposal checks
    SubDAOProposal storage subDAOProposal = LibSubDAO._getSubDAOProposal(proposalId);
    address subDAOInit = LibDAOStorage._getSubDAOInit();
    address subDAO = SubDAOInit(subDAOInit).initSubDAOType0(subDAOProposal.amountOfKeys, subDAOProposal.thresholdForProposal, subDAOProposal.keyHolders);

    ITreasury.Proposal storage proposal = LibTreasury._getTreasuryProposal(proposalId);

    require(proposal.proposalAccepted && !proposal.proposalExecuted, "Proposal does not accepted.");
    proposal.proposalExecuted = true;

    address destination = proposal.destinationAddress;
    uint value = proposal.value;
    bytes memory callData = proposal.callData;

    assembly {
      result := call(gas(), destination, value, add(callData, 0x20), mload(callData), 0, 0)
    }

    // return data needed?
    // also maybe depend on result delete only proposalVoting if result 0

    //remove proposal and proposal voting
    LibTreasury._removeTreasuryPropopal(proposalId);
    LibTreasury._removeTreasuryPropopalVoting(proposalId);

    emit ProposalExecuted(proposalId, destination, value, callData);
  }

}
*/
