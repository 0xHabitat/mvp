// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// temporary solution to change owner to addressesProvider

import {LibDAOStorage} from "../libraries/dao/LibDAOStorage.sol";
import {LibHabitatDiamond} from "../libraries/LibHabitatDiamond.sol";

/**
 * @title RemoveDiamondCutInit - Temporary contract, used in switch from
 *                               ownership to DAO logic.
 * @author @roleengineer
 */
contract RemoveDiamondCutInit {
  function setAddressesProviderInsteadOfOwner() external {
    address ap = LibDAOStorage._getDAOAddressesProvider();
    LibHabitatDiamond.setAddressesProvider(ap);
  }
}
