// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";
import { ERC20MetadataStorage } from "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";
import { ERC20BaseStorage } from "@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol";

contract TokenInit is ERC20BaseInternal {  
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ERC20BaseStorage for ERC20BaseStorage.Layout;  
    function init() external {

        ERC20MetadataStorage.Layout storage t = 
        ERC20MetadataStorage.layout();

        t.setName("Token");
        t.setSymbol("TKN");
        t.setDecimals(8);

        _mint(msg.sender, 1000);
    }
}