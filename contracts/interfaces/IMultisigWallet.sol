// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultisigWallet {

  function initialize(address _dao, address[] memory _signers, uint256 _quorum) external;

  function execute(uint256 _proposalId) external;

  function getSigners() external view returns (address[] memory);
}
