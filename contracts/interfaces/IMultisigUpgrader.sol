// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
* @notice a multisig wallet (and clone factory) for upgrading diamonds
* @dev signers and quorum cannot change once initialized
*/

interface IMultisigUpgrader {

  function initialize(address _dao, address[] memory _signers, uint256 _quorum) external;

  /// @notice adds 1 upgradeCredit to diamond for the multisigUpgrader
  /// @dev called from Governance.sol
  function execute(uint256 _proposalId) external;

  function getSigners() external view returns (address[] memory);
}
