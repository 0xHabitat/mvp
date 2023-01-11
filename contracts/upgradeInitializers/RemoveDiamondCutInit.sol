// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// temporary solution to change owner to addressesProvider

import {LibDAOStorage} from "../libraries/dao/LibDAOStorage.sol";
import {LibHabitatDiamond} from "../libraries/LibHabitatDiamond.sol";

contract RemoveDiamondCutInit {
  function setAddressesProviderInsteadOfOwner() external {
    address ap = LibDAOStorage._getDAOAddressesProvider();
    LibHabitatDiamond.setAddressesProvider(ap);
  }
}
