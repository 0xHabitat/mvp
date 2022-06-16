// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20BaseInternal } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';
import { ERC20BaseStorage } from '@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol';
import { MinimalProxyFactory } from '@solidstate/contracts/factory/MinimalProxyFactory.sol';

contract TokenInit is ERC20BaseInternal, MinimalProxyFactory {  
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ERC20BaseStorage for ERC20BaseStorage.Layout;

    string public name;
    string public symbol;
    uint8 public decimals;
    address[] public recipients;
    uint256[] public amounts;

    function set(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals, 
        address[] memory _recipients, 
        uint256[] memory _amounts
    ) external {
        require (recipients.length == amounts.length, 
        'TokenInit: each recipient should be assigned an amount');
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        recipients = _recipients;
        amounts = _amounts;
    }

    function proxify(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals, 
        address[] memory _recipients, 
        uint256[] memory _amounts
    ) public returns (address) {
        address instance = _deployMinimalProxy(address(this));
        TokenInit(instance).set(_name, _symbol, _decimals, _recipients, _amounts);
        return instance;
    }

    function init() external {
        ERC20MetadataStorage.Layout storage t = ERC20MetadataStorage.layout();

        t.setName(name);
        t.setSymbol(symbol);
        t.setDecimals(decimals);

        for (uint i; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
    }
}