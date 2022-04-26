// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IManagementSystem } from "./IManagementSystem.sol";

interface ISubDAO {

    struct SubDAOStorage {
      string subDAOName;
      string purpose;
      string info;
      string socials;
      address mainDAO;
      bytes32 immutable managementSystemPosition;
      address[] createdSubDAOs;
    }

    function getSubDAOName() external view returns(string);

    function getSubDAOPurpose() external view returns(string);

    function getSubDAOInfo() external view returns(string);

    function getSubDAOSocials() external view returns(string);

    function getMainDAO() external view returns(address);

    function hasSubDAOs() external view returns(bool);

    function getCreatedSubDAOs() external view returns(address[] memory);

    function isSubDAOOf(address _mainDAO) external view returns(bool);

    function isMainDAOFor(address _subDAO) external view returns(bool);

    function getManagementSystem() external view returns(IManagementSystem.ManagementSystem memory);

    function getGovernanceVotingSystem() external view returns(IManagementSystem.VotingSystem memory);

    function getTreasuryVotingSystem() external view returns(IManagementSystem.VotingSystem memory);

    function getSubDAOCreationVotingSystem() external view returns(IManagementSystem.VotingSystem memory);

    function getVotingPowerManager() external view returns(address);

    function getGovernanceERC20Token() external view returns(address);

    function getGovernanceSigners() external view returns(address[] memory);

    function getTreasurySigners() external view returns(address[] memory);

    function getSubDAOCreationSigners() external view returns(address[] memory);

    function isGovernanceSigner(address _signer) external view returns(bool);

    function isTreasurySigner(address _signer) external view returns(bool);

    function isSubDAOCreationSigner(address _signer) external view returns(bool);
}
