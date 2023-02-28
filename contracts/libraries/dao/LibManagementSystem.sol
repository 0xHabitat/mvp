// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IManagementSystem} from "../../interfaces/dao/IManagementSystem.sol";
import {IProposal} from "../../interfaces/IProposal.sol";

interface IDecider {
  function deciderType() external returns (IManagementSystem.DecisionType);
}

library LibManagementSystem {
  bytes32 constant MANAGEMENT_SYSTEMS_POSITION =
    keccak256("habitat.diamond.standard.management.systems.storage");

  /*
  struct ManagementSystem {
    string nameMS;
    DecisionType decisionType;
    bytes32 dataPosition;
    address currentDecider;
  }
*/

  // general function to read managementSystems human readable
  // return value is ManagementSystem array
  function _getManagementSystemsHR()
    internal
    view
    returns (IManagementSystem.ManagementSystem[] memory msshr)
  {
    bytes32[] memory msPositions = _getMSPositionsValues();
    msshr = new IManagementSystem.ManagementSystem[](msPositions.length);
    for (uint256 i = 0; i < msPositions.length; i++) {
      msshr[i] = _getManagementSystemByPosition(msPositions[i]);
    }
  }

  function _getModuleNames() internal view returns (string[] memory moduleNames) {
    bytes32[] memory msPositions = _getMSPositionsValues();
    moduleNames = new string[](msPositions.length);
    for (uint256 i = 0; i < msPositions.length; i++) {
      bytes32 pos = msPositions[i];
      bytes32 moduleName32;
      assembly {
        moduleName32 := sload(pos)
      }
      string memory moduleName = toString(moduleName32);
      moduleNames[i] = moduleName;
    }
  }

  // general function to set new management system (module)
  function _setNewManagementSystem(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    address deciderAddress
  ) internal {
    bytes32 managementSystemsPosition = MANAGEMENT_SYSTEMS_POSITION;

    // check the length of name - must be 31bytes max
    uint256 nameLength;

    assembly {
      nameLength := mload(msName)
    }

    require(nameLength <= uint256(31), "Management system name must be less than 32bytes.");

    // check decider - must be correct decision type
    IManagementSystem.DecisionType _decisionType = IDecider(deciderAddress).deciderType();
    // maybe don't use a param, but instead take value directly from decider?
    require(
      _decisionType == decisionType,
      "Decider contract has not the same decision type as declared."
    );

    uint256 numberOfManagementSystems;
    assembly {
      numberOfManagementSystems := sload(managementSystemsPosition)
    }

    bytes32 positionOfNewMS = bytes32(
      uint256(MANAGEMENT_SYSTEMS_POSITION) + uint256(4 * numberOfManagementSystems + 1)
    );
    // store it's position
    bytes32 msName32;
    assembly {
      msName32 := add(mul(mload(msName), 0x02), mload(add(msName, 0x20)))
    }

    bytes32 slotStoringMSPos = keccak256(bytes.concat(msName32, MANAGEMENT_SYSTEMS_POSITION));

    assembly {
      sstore(slotStoringMSPos, positionOfNewMS)
    }

    bytes32 dataPosition = keccak256(
      abi.encodePacked(address(this), "managementSystem", msName, numberOfManagementSystems)
    );

    // store ms data
    assembly {
      // store ms name
      sstore(positionOfNewMS, msName32)
      // store ms decision type
      sstore(add(positionOfNewMS, 0x01), decisionType)
      // store ms data position
      sstore(add(positionOfNewMS, 0x02), dataPosition)
      // store current decider
      sstore(add(positionOfNewMS, 0x03), deciderAddress)
    }

    // increase number of modules
    assembly {
      sstore(managementSystemsPosition, add(numberOfManagementSystems, 1))
    }
  }

  // general function to remove management system (module)
  function _removeManagementSystem(string memory msName) internal {
    bytes32 managementSystemsPosition = _getManagementSystemsPosition();
    bytes32 msPosition = _getManagementSystemPosition(msName);

    uint256 numberOfManagementSystems;
    assembly {
      numberOfManagementSystems := sload(managementSystemsPosition)
    }
    require(numberOfManagementSystems != 0, "Nothing to remove, how do you get here?");

    bytes32 msLastPosition = bytes32(
      uint256(managementSystemsPosition) + ((numberOfManagementSystems - 1) * 4) + 1
    );

    // remove position value stored in slot
    bytes32 msName32;
    assembly {
      msName32 := add(mul(mload(msName), 0x02), mload(add(msName, 0x20)))
    }
    bytes32 slotStoringMSPos = keccak256(bytes.concat(msName32, MANAGEMENT_SYSTEMS_POSITION));

    assembly {
      sstore(slotStoringMSPos, 0)
    }

    if (msLastPosition == msPosition) {
      // last ms

      // remove ms data
      assembly {
        // remove ms name
        sstore(msPosition, 0)
        // remove ms decision type
        sstore(add(msPosition, 0x01), 0)
        // remove ms data position
        sstore(add(msPosition, 0x02), 0)
        // remove current decider
        sstore(add(msPosition, 0x03), 0)
      }
    } else {
      //TODO check that msPosition still storing value
      // console.log(msPosition)
      // store new position of previous last ms in its slot
      bytes32 lastMSName;
      assembly {
        lastMSName := sload(msLastPosition)
      }
      bytes32 slotStoringPreviousLastMSPos = keccak256(
        bytes.concat(lastMSName, MANAGEMENT_SYSTEMS_POSITION)
      );
      assembly {
        sstore(slotStoringPreviousLastMSPos, msPosition)
      }

      // need to get last ms and replace
      // store last ms data to removing ms index and remove last
      assembly {
        // replace ms name
        sstore(msPosition, sload(msLastPosition))
        // replace ms decision type
        sstore(add(msPosition, 0x01), sload(add(msLastPosition, 0x01)))
        // replace ms data position
        sstore(add(msPosition, 0x02), sload(add(msLastPosition, 0x02)))
        // replace current decider
        sstore(add(msPosition, 0x03), sload(add(msLastPosition, 0x03)))
        // remove last ms name
        sstore(msLastPosition, 0)
        // remove last ms decision type
        sstore(add(msLastPosition, 0x01), 0)
        // remove last ms data position
        sstore(add(msLastPosition, 0x02), 0)
        // remove last current decider
        sstore(add(msLastPosition, 0x03), 0)
      }
    }
    // decrease number of modules
    assembly {
      sstore(managementSystemsPosition, sub(numberOfManagementSystems, 1))
    }
  }

  function _getManagementSystem(
    string memory msName
  ) internal view returns (IManagementSystem.ManagementSystem memory ms) {
    bytes32 msPosition = _getManagementSystemPosition(msName);
    ms = _getManagementSystemByPosition(msPosition);
  }

  function _getDecisionType(
    string memory msName
  ) internal view returns (IManagementSystem.DecisionType) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    return ms.decisionType;
  }

  function _getDecider(string memory msName) internal view returns (address) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    return ms.currentDecider;
  }

  // set ms, get ms, change ms - module manager responsibility
  //function _completelyChangeManagementSystem() ??
  function _switchDeciderOfManagementSystem(
    string memory msName,
    address newDeciderAddress
  ) internal {
    IManagementSystem.DecisionType newDecisionType = IDecider(newDeciderAddress).deciderType();
    bytes32 msPosition = _getManagementSystemPosition(msName);
    IManagementSystem.ManagementSystem storage ms = _getManagementSystemByPosition(msPosition);
    ms.decisionType = newDecisionType;
    ms.currentDecider = newDeciderAddress;
  }

  function _getMSDataByName(
    string memory msName
  ) internal view returns (IManagementSystem.MSData storage msData) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    msData = _getMSDataByPosition(ms.dataPosition);
  }

  function _setMSSpecificDataForDecisionType(
    string memory msName,
    IManagementSystem.DecisionType decisionType,
    bytes memory specificData
  ) internal {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    msData.decisionSpecificData[decisionType] = specificData;
  }

  // check if this is needed - we also have LibDecisionSystemSpecificData
  function _getMSDecisionTypeSpecificDataMemory(
    string memory msName
  ) internal view returns (bytes memory specificData) {
    IManagementSystem.ManagementSystem memory ms = _getManagementSystem(msName);
    require(ms.dataPosition != bytes32(0), "Mananagement system is not set.");
    IManagementSystem.MSData storage msData = _getMSDataByPosition(ms.dataPosition);
    return msData.decisionSpecificData[ms.decisionType];
  }

  function _getFreeProposalId(string memory msName) internal returns (uint256 proposalId) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    require(msData.activeProposalsIds.length < 200, "No more proposals pls");
    msData.proposalsCounter = msData.proposalsCounter + uint128(1);
    proposalId = uint256(msData.proposalsCounter);
    msData.activeProposalsIds.push(proposalId);
  }

  function _getProposal(
    string memory msName,
    uint256 proposalId
  ) internal view returns (IProposal.Proposal storage proposal) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    proposal = msData.proposals[proposalId];
  }

  function _removeProposal(string memory msName, uint256 proposalId) internal {
    IProposal.Proposal storage proposal = _getProposal(msName, proposalId);
    delete proposal.proposalAccepted;
    delete proposal.destinationAddress;
    delete proposal.value;
    delete proposal.callData;
    delete proposal.proposalExecuted;
    delete proposal.executionTimestamp;
  }

  function _getActiveProposalsIds(string memory msName) internal view returns (uint256[] storage) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.activeProposalsIds;
  }

  function _addProposalIdToAccepted(string memory msName, uint256 proposalId) internal {
    uint256[] storage acceptedProposalsIds = _getAcceptedProposalsIds(msName);
    acceptedProposalsIds.push(proposalId);
  }

  function _removeProposalIdFromAcceptedList(string memory msName, uint256 proposalId) internal {
    uint256[] storage acceptedProposalsIds = _getAcceptedProposalsIds(msName);
    require(acceptedProposalsIds.length > 0, "No accepted proposals.");
    _removeElementFromUintArray(acceptedProposalsIds, proposalId);
  }

  function _removeProposalIdFromActiveList(string memory msName, uint256 proposalId) internal {
    uint256[] storage activeProposalsIds = _getActiveProposalsIds(msName);
    require(activeProposalsIds.length > 0, "No active proposals.");
    _removeElementFromUintArray(activeProposalsIds, proposalId);
  }

  function _getAcceptedProposalsIds(
    string memory msName
  ) internal view returns (uint256[] storage) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.acceptedProposalsIds;
  }

  function _getProposalsCount(string memory msName) internal view returns (uint256) {
    IManagementSystem.MSData storage msData = _getMSDataByName(msName);
    return msData.proposalsCounter;
  }

  // helper function
  function _removeElementFromUintArray(uint256[] storage array, uint256 element) internal {
    if (array[array.length - 1] == element) {
      array.pop();
    } else {
      // try to find array index
      uint256 indexId;
      for (uint256 index = 0; index < array.length; index++) {
        if (array[index] == element) {
          indexId = index;
        }
      }
      // check if element exist
      require(array[indexId] == element, "No element in an array.");
      // replace last
      array[indexId] = array[array.length - 1];
      array[array.length - 1] = element;
      array.pop();
    }
  }

  function toString(bytes32 source) internal pure returns (string memory result) {
    uint8 length = uint8(source[31]) / uint8(2);
    assembly {
      result := mload(0x40)
      // new "memory end" including padding (the string isn't larger than 32 bytes)
      mstore(0x40, add(result, 0x40))
      // store length in memory
      mstore(result, length)
      // write actual data
      mstore(add(result, 0x20), source)
    }
  }

  // Core internal functions

  // function returns managementSystems position

  function _getManagementSystemPosition(string memory msName) internal view returns (bytes32) {
    bytes32[] memory slots = _getAllSlotsStoringMSPositions();

    // calculate position
    bytes32 msName32;
    assembly {
      msName32 := add(mul(mload(msName), 0x02), mload(add(msName, 0x20)))
    }

    bytes32 slotStoringMSPos = keccak256(bytes.concat(msName32, MANAGEMENT_SYSTEMS_POSITION));

    bool msContains;

    for (uint256 i = 0; i < slots.length; i++) {
      if (slotStoringMSPos == slots[i]) {
        msContains = true;
      }
    }
    require(msContains, "Management system does not exist within DAO.");
    bytes32 msPosition;
    assembly {
      msPosition := sload(slotStoringMSPos)
    }
    return msPosition;
  }

  function _getManagementSystemByPosition(
    bytes32 position
  ) internal pure returns (IManagementSystem.ManagementSystem storage ms) {
    assembly {
      ms.slot := position
    }
  }

  function _getAllSlotsStoringMSPositions() internal view returns (bytes32[] memory slots) {
    bytes32 position = _getManagementSystemsPosition();
    uint256 numberOfManagementSystems;
    assembly {
      numberOfManagementSystems := sload(position)
    }
    slots = new bytes32[](numberOfManagementSystems);
    for (uint256 i = 0; i < numberOfManagementSystems; i++) {
      bytes32 msName;

      assembly {
        msName := sload(add(position, add(0x1, mul(0x04, i))))
      }
      slots[i] = keccak256(bytes.concat(msName, MANAGEMENT_SYSTEMS_POSITION));
    }
  }

  function _getMSPositionsValues() internal view returns (bytes32[] memory slotsValues) {
    bytes32[] memory slots = _getAllSlotsStoringMSPositions();
    slotsValues = new bytes32[](slots.length);
    for (uint256 i = 0; i < slots.length; i++) {
      bytes32 msPosition = slots[i];
      assembly {
        msPosition := sload(msPosition)
      }
      slotsValues[i] = msPosition;
    }
  }

  function _getMSDataByPosition(
    bytes32 position
  ) internal pure returns (IManagementSystem.MSData storage msData) {
    assembly {
      msData.slot := position
    }
  }

  // general function to read managementSystems
  // return value is bytes memory
  function _getManagementSystems() internal view returns (bytes memory managementSystems) {
    bytes32 position = _getManagementSystemsPosition();
    uint256 numberOfManagementSystems;
    assembly {
      numberOfManagementSystems := sload(position)
    }
    uint256 length = 32 + (4 * 32 * numberOfManagementSystems);
    managementSystems = new bytes(length);
    assembly {
      for {
        let i := 0
      } lt(mul(i, 0x20), length) {
        i := add(i, 0x01)
      } {
        let storedBlock32bytes := sload(add(position, i))
        mstore(add(managementSystems, add(0x20, mul(i, 0x20))), storedBlock32bytes)
      }
    }
  }

  function _getManagementSystemsPosition() internal pure returns (bytes32) {
    return MANAGEMENT_SYSTEMS_POSITION;
  }
}
