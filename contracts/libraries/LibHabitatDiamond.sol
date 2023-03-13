// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
// TODO for MS: add addresses and add active -> adjust diamondCut not to cut facets that are active ms through governance
library LibHabitatDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address addressesProvider;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event AddressesProviderUpdated(
    address indexed previousAddressesProvider,
    address indexed newAddressesProvider
  );

  // function can be called only by moduleManager
  function setAddressesProvider(address _newAddressesProvider) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousAddressesProvider = ds.addressesProvider;
    ds.addressesProvider = _newAddressesProvider;
    emit AddressesProviderUpdated(previousAddressesProvider, _newAddressesProvider);
  }

  function getAddressesProvider() internal view returns (address addressesProvider_) {
    addressesProvider_ = diamondStorage().addressesProvider;
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else {
        revert("LibDiamondCut: Incorrect FacetCutAction");
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  event FacetUpdated(address oldFacetAddress, address newFacetAddress);

  // function for governance module
  // allowes to update existing facets, source of upgrades is addresses providers
  // rule: to make update requires to replace all functions of previous facet
  // selectors array must start with selector that exist in a diamond storage
  // new functions could be added
  function updateFacet(address _newFacetAddress) internal {
    // this function can be called by governance (with modifier not change state)
    DiamondStorage storage ds = diamondStorage();
    // the source of facet address and selectors must be addresses provider
    IAddressesProvider addressesProvider = IAddressesProvider(getAddressesProvider());
    require(
      addressesProvider.facetAddressExist(_newFacetAddress),
      "Addresses provider does not contain the facet."
    );
    // get new facet selectors from addresses provider
    bytes4[] memory selectors = addressesProvider.getSelectors(_newFacetAddress);
    // get old facet address
    address oldFacetAddress = ds.selectorToFacetAndPosition[selectors[0]].facetAddress;
    require(
      oldFacetAddress != address(0),
      "Update rule is not followed: first selector does not exist in a diamond."
    );

    // get old facet selectors from diamond storage
    uint256 numberOfReplacedSelectors = ds
      .facetFunctionSelectors[oldFacetAddress]
      .functionSelectors
      .length;

    if (numberOfReplacedSelectors < selectors.length) {
      // divide selectors array on replace/add arrays
      bytes4[] memory selectorsToReplace = new bytes4[](numberOfReplacedSelectors);
      bytes4[] memory selectorsToAdd = new bytes4[](selectors.length - numberOfReplacedSelectors);
      uint256 replaceIndex;
      uint256 addIndex;
      for (uint256 i = 0; i < selectors.length; i++) {
        address facetAddress = ds.selectorToFacetAndPosition[selectors[i]].facetAddress;
        if (facetAddress == oldFacetAddress) {
          selectorsToReplace[replaceIndex] = selectors[i];
          replaceIndex += 1;
        } else if (facetAddress == address(0)) {
          selectorsToAdd[addIndex] = selectors[i];
          addIndex += 1;
        } else {
          revert("Update rule is not followed: tried to update two facets at once.");
        }
      }
      replaceFunctions(_newFacetAddress, selectorsToReplace);
      addFunctions(_newFacetAddress, selectorsToAdd);
    } else if (numberOfReplacedSelectors == selectors.length) {
      // check that all selectors are from old facet adddress and replace
      for (uint256 i = 0; i < selectors.length; i++) {
        address facetAddress = ds.selectorToFacetAndPosition[selectors[i]].facetAddress;
        require(
          facetAddress == oldFacetAddress,
          "Update rule is not followed: tried to update two facets at once."
        );
      }
      replaceFunctions(_newFacetAddress, selectors);
    } else {
      revert("Update rule is not followed: all existing selectors must be replaced.");
    }
    // old facet must be removed
    require(
      ds.facetFunctionSelectors[oldFacetAddress].functionSelectors.length == 0,
      "Old facet was not removed."
    );
    emit FacetUpdated(oldFacetAddress, _newFacetAddress);
  }

  event StateUpdated(address _init, bytes _calldata);

  // function for governance module - extended updateFacet with updating state
  function updateFacetAndState(address _newFacetAddress, bytes memory _calldata) internal {
    IAddressesProvider addressesProvider = IAddressesProvider(getAddressesProvider());
    address initAddress = addressesProvider.getInitForFacet(_newFacetAddress);
    require(initAddress != address(0), "State can not be change without init contract.");
    updateFacet(_newFacetAddress);
    initializeDiamondCut(initAddress, _calldata);
    emit StateUpdated(initAddress, _calldata);
  }

  // helper function for moduleManager
  function updateState(address initAddress, bytes memory callData) internal {
    require(initAddress != address(0), "State can not be change without init contract.");
    initializeDiamondCut(initAddress, callData);
    emit StateUpdated(initAddress, callData);
  }

  // helper function for moduleManager
  function addFacets(address[] memory facets, bytes4[][] memory selectors) internal {
    require(facets.length == selectors.length, "Array length does not match.");
    for (uint256 facetIndex; facetIndex < facets.length; facetIndex++) {
      addFunctions(facets[facetIndex], selectors[facetIndex]);
    }
  }

  // helper function for moduleManager
  function removeFacets(address[] memory facets) internal {
    DiamondStorage storage ds = diamondStorage();
    for (uint256 facetIndex; facetIndex < facets.length; facetIndex++) {
      bytes4[] memory functionSelectors = ds
        .facetFunctionSelectors[facets[facetIndex]]
        .functionSelectors;
      removeFunctions(facets[facetIndex], functionSelectors);
    }
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(
        oldFacetAddress == address(0),
        "LibDiamondCut: Can't add function that already exists"
      );
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(
        oldFacetAddress != _facetAddress,
        "LibDiamondCut: Can't replace function with same function"
      );
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
    // an immutable function is a function defined directly in a diamond
    require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facetAddress]
      .functionSelectors
      .length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
        lastSelectorPosition
      ];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(
        selectorPosition
      );
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      require(
        _calldata.length == 0,
        "LibDiamondCut: _init is address(0) but_calldata is not empty"
      );
    } else {
      require(
        _calldata.length > 0,
        "LibDiamondCut: _calldata is empty but _init is not address(0)"
      );
      if (_init != address(this)) {
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert("LibDiamondCut: _init function reverted");
        }
      }
    }
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}
