// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { EnumerableSet } from "@solidstate/contracts/utils/EnumerableSet.sol";

import "hardhat/console.sol";

library RepositoryStorage {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Layout {
        EnumerableSet.AddressSet _upgrades;
        //Team multisig => available upgrades
        mapping(address => uint8) availableUpgrades;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("diamond.standard.upgrade.repo.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _hasUpgrade(address upgrade) internal view returns (bool) {
        if (layout()._upgrades.contains(upgrade)) {
            return true;
        }
        return false;
    }

    function _viewUpgrades() internal view returns (address[] memory) {
        Layout storage l = layout();
        uint length = l._upgrades.length();
        address[] memory upgrades = new address[](length);
        for (uint i; i < length; i++) {
            upgrades[i] = l._upgrades.at(i);
        }
        return upgrades;
    }

    function _addUpgrade(address upgrade) internal {
        require(upgrade.isContract(), 
        "Repository: upgrade must be contract");
        RepositoryStorage.Layout storage l = RepositoryStorage.layout();
        require(l.availableUpgrades[msg.sender] >= 1, "RepositoryStorage: No upgrade available.");
        l._upgrades.add(upgrade);
        l.availableUpgrades[msg.sender] -= 1;
    }
}