// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RepositoryStorage } from "contracts/storage/RepositoryStorage.sol";

import { MultisigWallet, IMultisigWallet } from "contracts/external/MultisigWallet.sol";
import { MinimalProxyFactory } from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import 'hardhat/console.sol';


contract Repository is MinimalProxyFactory {

    event TeamDeployed(address);

    address immutable public multisig;
    constructor(address[] memory _signers, uint256 _quorum) {
        MultisigWallet wallet = new MultisigWallet();
        IMultisigWallet(wallet).initialize(address(this), _signers, _quorum);
        multisig = address(wallet);
    }

    function hasUpgrade(address upgrade) external view returns (bool) {
        return RepositoryStorage._hasUpgrade(upgrade);
    }

    function viewUpgrades() external view returns (address[] memory) {
        return RepositoryStorage._viewUpgrades();
    }

    function addUpgrade(address upgrade) external {
        RepositoryStorage._addUpgrade(upgrade);
    }

    function deployTeam(
        address[] memory _signers, uint256 _quorum) 
    external returns (address) {
        address team = _deployMinimalProxy(multisig);
        IMultisigWallet(team).initialize(address(this), _signers, _quorum);
        emit TeamDeployed(team);
        return team;
    }
}

