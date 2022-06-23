// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {HabitatDiamond} from "./HabitatDiamond.sol";
import {IDAO} from "./interfaces/dao/IDAO.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "./interfaces/IAddressesProvider.sol";
//import {IManagementSystem} from "./interfaces/dao/IManagementSystem.sol";
import {IUniswapV2Factory} from "./interfaces/token/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interfaces/token/IUniswapV2Pair.sol";
import {IWETH} from "./interfaces/token/IWETH.sol";
import {IERC20} from "./libraries/openzeppelin/IERC20.sol";

// management part

enum DecisionType {
  None,
  OnlyOwner,
  VotingPowerManagerERC20, // stake contract
  Signers // Gnosis
}

struct ManagementSystem {
  string nameMS; // very important that this item is bytes32, so the string is max 31 char
  DecisionType decisionType;
  bytes32 dataPosition;
}

// we can read ManagementSystemsV1 without this struct as a returned value,
// but represent it as fixed size ManagementSystem[], because we know the number
struct ManagementSystemsV1 {
  uint numberOfManagementSystems;
  ManagementSystem setAddChangeManagementSystem;
  ManagementSystem governance;
  ManagementSystem treasury;
  ManagementSystem subDAOsCreation;
}

struct ManagementSystemData {
  bool isSetupComplete;

}

struct Token {
  string tokenName;
}

enum ETHPair {
  None,
  UniV2,
  Sushi,
  UniPlusSushi
}
/*
struct VPMTokens {
  VPMToken nativeGovernanceToken;
  VPMToken uniDerivative;
  VPMToken sushiDerivative;
}

struct VPMToken {
  uint coefficient;
  //uint price
}

*/
// important to deploy from one address and same nonce for each contract on different blockchains
contract HabitatDiamondFactory {

  mapping(string => mapping(string => address)) public getDAOAddress;
  address[] public allDAOs;

  event DAOCreated(string indexed daoName, string indexed daoSocials, address daoAddress);

  /**
   * @dev function deploys habitat diamond.
   * @param managementSystemsNameAndTypeValues must be bytes32 blocks array where first value
            represents number of management systems and next values are tuples that are
            ManagementSystem is represented as sequence of two bytes32 values, first is:
              Name of ManagementSystem that type is string, but value must be bytes32 length,
              means that the name must be <= 31 bytes
              the encoding must be done by this rule:
              https://docs.soliditylang.org/en/v0.8.14/internals/layout_in_storage.html#bytes-and-string
            and second value is:
              Decision Type of the related managementSystem (recommended order:
                0 - setAddChangeManagementSystem
                1 - governanceManagementSystem
                2 - treasuryManagementSystem
                3 - subDAOCreationManagementSystem)
            is done as a bytes array to have ability to extend
   */
  function deployHabitatDiamond(
    address addressesProvider,
    IDAO.DAOMeta memory daoMetaData,
    bytes calldata managementSystemsNameAndTypeValues,
    bytes[] memory managementSystemsSetupData,
    bool basic,
    Token token
  ) public payable returns(address habitatDiamond) {
    // deploy HabitatDiamond
    // first param contractOwner - setting Factory as contractOwner and at the end of call move ownership to msg.sender -> later need to adjust replacing ownership logic to voting logic (a.k.a. Diamond is owner of itself)
    require(getDAOAddress[daoMetaData.daoName][daoMetaData.socials] == address(0), 'DAO exists.');
    require(managementSystemsNameAndTypeValues.length % 32 == 0, "Must be bytes32 blocks");
    require(managementSystemsNameAndTypeValues[0:32] * 64 + 32 == managementSystemsNameAndTypeValues.length, "Wrong managementSystems encoding.");
    bytes memory habitatDiamondConstructorArgs = abi.encode(address(this), addressesProvider, daoMetaData);
    bytes memory bytecode = bytes.concat(type(HabitatDiamond).creationCode, habitatDiamondConstructorArgs);
    bytes32 salt = keccak256(abi.encode(daoMetaData.daoName, daoMetaData.socials));
    assembly {
      habitatDiamond := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    getDAOAddress[daoMetaData.daoName][daoMetaData.socials] = habitatDiamond;
    emit DAOCreated(daoMetaData.daoName, daoMetaData.socials, habitatDiamond);
    // Temporary add the writeToStorageBytes32Blocks external function from the StorageWriterFacet
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
    IAddressesProvider.Facet memory storageWriterFacet = IAddressesProvider(addressesProvider).getStorageWriterFacet();
    cut[0] = IDiamondCut.FacetCut({
      facetAddress: storageWriterFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: storageWriterFacet.functionSelectors
    });
    habitatDiamond.diamondCut(cut, address(0), "");
    // second set values to ManagementSystems - i think better to move to HabitatDiamond
    bytes32 managementSystemsPosition = habitatDiamond.getManagementSystemsPosition();
    uint numberOfManagementSystems = managementSystemsNameAndTypeValues[0:32];

    bytes memory managementSystemsValues = bytes.concat(bytes32(numberOfManagementSystems));
    for (uint i = 0; i < numberOfManagementSystems; i++) {
      bytes32 managementSystemName = bytes32(managementSystemsNameAndTypeValues[32+96*i:96*i+64]);
      require(managementSystemName % 2 == 0, "the last bit of name must not be set");
      bytes32 managementSystemType = bytes32(managementSystemsNameAndTypeValues[64+96*i:96*i+96]);
      require(bytes32(uint256(255)) >= managementSystemType, "Management system type is out of bounds.");
      bytes32 managementSystemDataPosition = keccak256(abi.encodePacked(habitatDiamond, "managementSystem", managementSystemName, i));
      managementSystemsValues = bytes.concat(managementSystemsValues, managementSystemName, managementSystemType, managementSystemDataPosition);
    }
    habitatDiamond.writeToStorageBytes32Blocks(managementSystemsPosition, managementSystemsValues);

    // second step - analyze MS and deploy everything that is needed
    // first read MS
    //bytes32 managementSystemsPosition = habitatDiamond.getManagementSystemsPosition();
    uint managementSystemsAmount = uint(habitatDiamond.readStorageSlot(managementSystemsPosition));
    bytes memory managementSystems = habitatDiamond.readStorageBytes32Blocks(managementSystemsPosition + 1, managementSystemsAmount * 96);

    for (uint i = 0; i < managementSystemsAmount; i++) {
      bytes32 managementSystemName;
      bytes32 managementSystemType;
      bytes32 managementSystemDataPosition;
      assembly {
        managementSystemName := mload(add(managementSystems,add(0x20, mul(i,0x60))))
        managementSystemType := mload(add(managementSystems, add(0x40, mul(i,0x60))))
        managementSystemDataPosition := mload(add(managementSystems, add(0x60, mul(i,0x60))))
      }
      // shit is about governance diamondCut - should be resolved somehow, because
      // here is onlyOwner-Factory and here potentially we change it to another system
      // and cannot call diamondCut anymore, so i believe we must either do it at the end
      // or distinguish with governance - another option
      // first of all i need to define who is able to call diamondCut - governance or setAddChangeManagementSystem
      // (seems like both, but second one can only change data related to MS and first one is not able to do it)
      bool nameDefined;
      // bytes32 representation of a string "setAddChangeManagementSystem" is 0x7365744164644368616e67654d616e6167656d656e7453797374656d00000038
      if (managementSystemName == 0x7365744164644368616e67654d616e6167656d656e7453797374656d00000038) {
        nameDefined = true;
        // TODO: define what is specific for this ms in terms of set up
      }
      // bytes32 representation of a string "governance" is 0x676f7665726e616e636500000000000000000000000000000000000000000014
      if (managementSystemName == 0x676f7665726e616e636500000000000000000000000000000000000000000014) {
        nameDefined = true;
        // TODO: define what is specific for this ms
      }
      // bytes32 representation of a string "treasury" is 0x7472656173757279000000000000000000000000000000000000000000000010
      if (managementSystemName == 0x7472656173757279000000000000000000000000000000000000000000000010) {
        nameDefined = true;
        // TODO: define what is specific for this ms
      }
      // bytes32 representation of a string "subDAOsCreation" is 0x73756244414f734372656174696f6e000000000000000000000000000000001e
      if (managementSystemName == 0x73756244414f734372656174696f6e000000000000000000000000000000001e) {
        nameDefined = true;
        // TODO: define what is specific for this ms
      }

      if (!nameDefined) {
        (address addressToCall, bytes4 functionSelector) = IAddressesProvider(addressesProvider).getAddressAndFunctionToCall(managementSystemName);
        require(addressToCall != address(0), "Unknown name of management system.");
        bytes memory managementSystemSetupData = managementSystemsSetupData[i];
        addressToCall.delegateCall(bytes.concat(functionSelector, managementSystemDataPosition, managementSystemSetupData)); // write this function
      }

      // the below switch will be done as an internal function that is called inside the above switch

      if (uint8(uint256(managementSystemType)) == uint8(DecisionType.OnlyOwner)) {
        address onlyOwnerInit = IAddressesProvider(addressesProvider).getOnlyOwnerInit();
        bytes memory managementSystemSetupData = managementSystemsSetupData[i];
        _setupOnlyOwner(managementSystemDataPosition, onlyOwnerInit, managementSystemSetupData);
      }

      if (uint8(uint256(managementSystemType)) == uint8(DecisionType.VotingPowerManagerERC20)) {
        address votingPowerInit = IAddressesProvider(addressesProvider).getVotingPowerInit();
        bytes memory managementSystemSetupData = managementSystemsSetupData[i];
        _setupVotingPowerERC20(managementSystemDataPosition, votingPowerInit, managementSystemSetupData);
      }

      if (uint8(uint256(managementSystemType)) == uint8(DecisionType.Signers)) {
        address signersInit = IAddressesProvider(addressesProvider).getSignersInit();
        bytes memory managementSystemSetupData = managementSystemsSetupData[i];
        _setupSigners(managementSystemDataPosition, signersInit, managementSystemSetupData);
      }

      if (uint8(uint256(managementSystemType)) > uint8(DecisionType.Signers)) {
        (address addressToCall, bytes4 functionSelector) = IAddressesProvider(addressesProvider).getAddressAndFunctionToCall(managementSystemType);
        require(addressToCall != address(0), "Unknown decision type for management system.");
        bytes memory managementSystemSetupData = managementSystemsSetupData[i];
        addressToCall.delegateCall(bytes.concat(functionSelector, managementSystemDataPosition, managementSystemSetupData)); // write this function
      }

    }

    // second deploy HBT token

/*
    // deploy ETHPair
    address uniV2Pair;
    uint uniV2coefficient;
    address sushiV2Pair;
    uint sushiV2coefficient;
    address wETH = IAddressesProvider(addressesProvider).getWETH();
    if (ethPair == ETHPair.UniPlusSushi) {
      address uniswapV2Factory = IAddressesProvider(addressesProvider).getUniswapV2Factory();
      (uniV2Pair, uniV2coefficient) = createV2Pair(uniswapV2Factory, habitatDiamond, wETH);
      address sushiV2Factory = IAddressesProvider(addressesProvider).getSushiV2Factory();
      (sushiV2Pair, sushiV2coefficient) = createV2Pair(sushiV2Factory, habitatDiamond, wETH);
    } else {
      if (ethPair == ETHPair.UniV2) {
        address uniswapV2Factory = IAddressesProvider(addressesProvider).getUniswapV2Factory();
        (uniV2Pair, uniV2coefficient) = createV2Pair(uniswapV2Factory, habitatDiamond, wETH);
      } else if (ethPair == ETHPair.Sushi) {
        address sushiV2Factory = IAddressesProvider(addressesProvider).getSushiV2Factory();
        (sushiV2Pair, sushiV2coefficient) = createV2Pair(sushiV2Factory, habitatDiamond, wETH);
      }
    }
*/
    // make cutting

    // remove StorageWriterFacet
    cut[0].facetAddress = address(0);
    cut[0].action = IDiamondCut.FacetCutAction.Remove;
    habitatDiamond.diamondCut(cut, address(0), "");
    // move ownership to msg.sender
    bytes memory transferOwnershipCall = abi.encodeWithSignature('transferOwnership(address)', msg.sender);
    (bool suc,) = habitatDiamond.call(transferOwnershipCall);
    require(suc);
  }

  function _setupOnlyOwner(bytes32 msDataPosition, address initContract, bytes memory setupData) internal {
    revert("not implemented");
  }

  function _setupVotingPowerERC20(bytes32 msDataPosition, address initContract, bytes memory setupData) internal {
    revert("not implemented");
  }

  function _setupSigners(bytes32 msDataPosition, address initContract, bytes memory setupData) internal {
    revert("not implemented");
  }

  function createV2Pair(address factoryAddress, address habitatDiamond, address wETH) internal returns(address pairAddress, uint coefficient) {
    // replace later with the price, now 0.1ETH - 100HBT
    uint amountETH = msg.value;
    require(amountETH == 100000000 gwei);
    IWETH(wETH).deposit{value: amountETH}();
    pairAddress = IUniswapV2Factory(factoryAddress).createPair(habitatDiamond, wETH);
    uint amountGovToken = 100 * 10 ** 18;
    // before in HBTDiamond constructor we must transfer 100 * 10 ** 18 to this contract
    assert(IWETH(wETH).transfer(pairAddress, amountETH));
    assert(IERC20(habitatDiamond).transfer(pairAddress, amountGovToken));
    IUniswapV2Pair(pairAddress).mint(habitatDiamond);
    coefficient = IERC20(pairAddress).balanceOf(habitatDiamond) / 100 * 1000; // 1000 is precision in case we want 1HBT - 1 votingPower; hbtAddress: 1000 in coefficients mapping
  }
}
