// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RepositoryStorage } from "contracts/storage/RepositoryStorage.sol";

import { MultisigUpgrader, IMultisigUpgrader } from "contracts/external/MultisigUpgrader.sol";
import { MinimalProxyFactory } from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import 'hardhat/console.sol';


contract Repository is MinimalProxyFactory {

    event TeamDeployed(address team, address diamond);

    address immutable public multisigUpgraderTemplate;
    constructor(address[] memory _signers, uint256 _quorum) {
        MultisigUpgrader upgrader = new MultisigUpgrader();
        IMultisigUpgrader(upgrader).initialize(address(this), _signers, _quorum);
        multisigUpgraderTemplate = address(upgrader);
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

    ///IDEA require token burn
    function deployTeam(
        address[] memory _signers, uint256 _quorum) 
    external returns (address) {
        address team = _deployMinimalProxy(multisigUpgraderTemplate);
        IMultisigUpgrader(team).initialize(address(this), _signers, _quorum);
        emit TeamDeployed(team, address(this));
        return team;
    }
}

