// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "./IManagementSystem.sol";

interface IDAO {
  struct DAOStorage {
    string daoName;
    string purpose;
    string info;
    string socials;
    bytes32 managementSystemPosition;
    address[] createdSubDAOs;
  }

  function getDAOName() external view returns (string memory);

  function getDAOPurpose() external view returns (string memory);

  function getDAOInfo() external view returns (string memory);

  function getDAOSocials() external view returns (string memory);

  function hasSubDAOs() external view returns (bool);

  function getCreatedSubDAOs() external view returns (address[] memory);

  function isMainDAOFor(address _subDAO) external view returns (bool);

  function getManagementSystem() external view returns (IManagementSystem.ManagementSystem memory);

  function getGovernanceVotingSystem() external view returns (IManagementSystem.VotingSystem);

  function getTreasuryVotingSystem() external view returns (IManagementSystem.VotingSystem);

  function getSubDAOCreationVotingSystem() external view returns (IManagementSystem.VotingSystem);

  function getVotingPowerManager() external view returns (address);

  function getGovernanceERC20Token() external view returns (address);

  function getGovernanceSigners() external view returns (address[] memory);

  function getTreasurySigners() external view returns (address[] memory);

  function getSubDAOCreationSigners() external view returns (address[] memory);

  function isGovernanceSigner(address _signer) external view returns (bool);

  function isTreasurySigner(address _signer) external view returns (bool);

  function isSubDAOCreationSigner(address _signer) external view returns (bool);
  /*
    function changeManagementSystemForTreasury()
    function changeManagementSystemForGovernance()
    function changeManagementSystemForCreationSubDAOs()
    */
}
