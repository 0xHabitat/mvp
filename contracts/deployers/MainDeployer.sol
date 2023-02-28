// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

interface IDAOViewer {
  function getDAOAddressesProvider() external view returns (address);
}

interface ISetVotingPowerHolder {
  function setVotingPowerHolder(address _votingPowerHolder) external;
}

interface IERC20Deployer {
  function deployERC20InitialDistributorMainPools(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 totalSupply,
    uint160[2] memory _sqrtPricesX96,
    address initialDistributorOwner
  ) external returns (address, address);

  function deployLastPool(address hbt, uint160[2] memory _sqrtPricesX96) external;

  function deployThreePools(
    address hbt,
    address pairAddress,
    uint160[2] memory _sqrtPricesX96
  ) external;
}

interface IDeciderVotingPowerDeployer {
  function deployDeciderVotingPower(
    address _dao,
    address _daoSetter,
    address _stakeContract,
    uint256 _precision
  ) external returns (address);
}

interface IDeciderSignersDeployer {
  function deployDeciderSigners(
    address _dao,
    address _daoSetter,
    address _gnosisSafe
  ) external returns (address);
}

interface IVotingPowerManagerDeployer {
  function deployVotingPowerManagerERC20UniV3(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external returns (address);
}

interface IDAODeploer {
  struct DAOMeta {
    string daoName;
    string purpose;
    string info;
    string socials;
  }

  enum DecisionType {
    None,
    OnlyOwner,
    VotingPowerManagerERC20, // stake contract
    Signers // Gnosis
    //ERC20PureVoting, // Compound
    //BountyCreation - gardener, worker, reviewer - 3 signers
  }

  function deployDAO(
    address addressesProvider,
    DAOMeta memory daoMetaData,
    bytes memory msCallData
  ) external returns (address);
}

interface IOwnership {
  function transferOwnership(address _newOwner) external;
}

contract MainDeployer {
  event VotingPowerManagerDecider(
    address indexed votingPowerManager,
    address indexed votingPowerDecider
  );

  IERC20Deployer public erc20Deployer;
  IDeciderSignersDeployer public deciderSignersDeployer;
  IDeciderVotingPowerDeployer public deciderVotingPowerDeployer;
  IVotingPowerManagerDeployer public votingPowerManagerDeployer;
  IDAODeploer public daoDeployer;

  constructor(
    address _erc20Deployer,
    address _deciderSignersDeployer,
    address _deciderVotingPowerDeployer,
    address _votingPowerManagerDeployer,
    address _daoDeployer
  ) {
    erc20Deployer = IERC20Deployer(_erc20Deployer);
    deciderSignersDeployer = IDeciderSignersDeployer(_deciderSignersDeployer);
    deciderVotingPowerDeployer = IDeciderVotingPowerDeployer(_deciderVotingPowerDeployer);
    votingPowerManagerDeployer = IVotingPowerManagerDeployer(_votingPowerManagerDeployer);
    daoDeployer = IDAODeploer(_daoDeployer);
  }

  function deployGovernanceToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 totalSupply,
    uint160[2] memory _sqrtPricesX96
  ) external returns (address, address) {
    (address govToken, address distributor) = erc20Deployer.deployERC20InitialDistributorMainPools(
      tokenName,
      tokenSymbol,
      totalSupply,
      _sqrtPricesX96,
      msg.sender
    );
    return (govToken, distributor);
  }

  function deployLastMainPool(address hbt, uint160[2] memory _sqrtPricesX96) external {
    erc20Deployer.deployLastPool(hbt, _sqrtPricesX96);
  }

  function deployThreePools(
    address hbt,
    address pairAddress,
    uint160[2] memory _sqrtPricesX96
  ) external {
    erc20Deployer.deployThreePools(hbt, pairAddress, _sqrtPricesX96);
  }

  function deployVotingPowerAndSignersDeciders(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens,
    uint256 _precision,
    address _dao,
    address _daoSetter,
    address _gnosisSafe
  ) external returns (address deciderSigners, address deciderVotingPower, address stakeContract) {
    deciderSigners = deciderSignersDeployer.deployDeciderSigners(_dao, _daoSetter, _gnosisSafe);

    stakeContract = votingPowerManagerDeployer.deployVotingPowerManagerERC20UniV3(
      _nfPositionManager,
      _governanceToken,
      _legalPairTokens
    );

    deciderVotingPower = deciderVotingPowerDeployer.deployDeciderVotingPower(
      _dao,
      _daoSetter,
      stakeContract,
      _precision
    );

    ISetVotingPowerHolder(stakeContract).setVotingPowerHolder(deciderVotingPower);

    emit VotingPowerManagerDecider(stakeContract, deciderVotingPower);
  }

  function deployDAO(
    address addressesProvider,
    IDAODeploer.DAOMeta memory daoMetaData,
    string[] memory msNames,
    IDAODeploer.DecisionType[] memory decisionTypes,
    address[] memory deciders,
    bytes[] memory votingPowerSpecificDatas,
    bytes[] memory signersSpecificDatas
  ) external returns (address) {
    bytes memory msCallData = abi.encodeWithSignature(
      "initManagementSystems(string[],uint8[],address[])",
      msNames,
      decisionTypes,
      deciders
    );

    address dao = daoDeployer.deployDAO(addressesProvider, daoMetaData, msCallData);

    makeModuleViewerCut(dao);

    makeSpecificDataCut(dao, msNames, votingPowerSpecificDatas, signersSpecificDatas);

    makeModuleManagerCut(dao);

    makeGovernanceCut(dao);

    makeTreasuryCut(dao);

    removeOwnershipAndDiamondCut(dao);

    return dao;
  }

  // temporary make external, but probably has to be in ms initialization
  function makeModuleViewerCut(address dao) internal {
    // make module viewer cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory moduleViewerCut = new IDiamondCut.FacetCut[](1);
    // Add module viewer facet
    IAddressesProvider.Facet memory moduleViewerFacet = IAddressesProvider(addressesProvider)
      .getModuleViewerFacet();

    moduleViewerCut[0] = IDiamondCut.FacetCut({
      facetAddress: moduleViewerFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: moduleViewerFacet.functionSelectors
    });

    IDiamondCut(dao).diamondCut(moduleViewerCut, address(0), "");
  }

  function makeSpecificDataCut(
    address dao,
    string[] memory msNames,
    bytes[] memory votingPowerSpecificDatas,
    bytes[] memory signersSpecificDatas
  ) internal {
    // make specific data cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory specificDataCut = new IDiamondCut.FacetCut[](1);
    // Add specific data facet
    IAddressesProvider.Facet memory specificDataFacet = IAddressesProvider(addressesProvider)
      .getSpecificDataFacet();

    specificDataCut[0] = IDiamondCut.FacetCut({
      facetAddress: specificDataFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: specificDataFacet.functionSelectors
    });

    address specificDataInit = IAddressesProvider(addressesProvider).getSpecificDataInit();
    bytes memory specificDataCallData = abi.encodeWithSignature(
      "initVotingPowerAndSignersSpecificData(string[],bytes[],bytes[])",
      msNames,
      votingPowerSpecificDatas,
      signersSpecificDatas
    );

    IDiamondCut(dao).diamondCut(specificDataCut, specificDataInit, specificDataCallData);
  }

  function makeModuleManagerCut(address dao) internal {
    // make treasury cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory moduleManagerCut = new IDiamondCut.FacetCut[](1);
    // Add module manager facet
    IAddressesProvider.Facet memory moduleManagerFacet = IAddressesProvider(addressesProvider)
      .getModuleManagerFacet();

    moduleManagerCut[0] = IDiamondCut.FacetCut({
      facetAddress: moduleManagerFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: moduleManagerFacet.functionSelectors
    });

    IDiamondCut(dao).diamondCut(moduleManagerCut, address(0), "");
  }

  function makeGovernanceCut(address dao) internal {
    // make treasury cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory governanceCut = new IDiamondCut.FacetCut[](1);
    // Add module manager facet
    IAddressesProvider.Facet memory governanceFacet = IAddressesProvider(addressesProvider)
      .getGovernanceFacet();

    governanceCut[0] = IDiamondCut.FacetCut({
      facetAddress: governanceFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: governanceFacet.functionSelectors
    });

    IDiamondCut(dao).diamondCut(governanceCut, address(0), "");
  }

  function makeTreasuryCut(address dao) internal {
    // make treasury cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory treasuryCut = new IDiamondCut.FacetCut[](2);
    // Add treasury actions facet
    IAddressesProvider.Facet memory treasuryActionsFacet = IAddressesProvider(addressesProvider)
      .getTreasuryActionsFacet();

    treasuryCut[0] = IDiamondCut.FacetCut({
      facetAddress: treasuryActionsFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: treasuryActionsFacet.functionSelectors
    });

    // Add the treasury default callback facet
    IAddressesProvider.Facet memory treasuryDefaultCallbackFacet = IAddressesProvider(
      addressesProvider
    ).getTreasuryDefaultCallbackHandlerFacet();

    treasuryCut[1] = IDiamondCut.FacetCut({
      facetAddress: treasuryDefaultCallbackFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: treasuryDefaultCallbackFacet.functionSelectors
    });

    IDiamondCut(dao).diamondCut(treasuryCut, address(0), "");
  }

  // temporary solution - later edit with better experience
  function removeOwnershipAndDiamondCut(address dao) internal {
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    // make a default cut
    IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
    // Add the diamondCut external function from the diamondCutFacet
    IAddressesProvider.Facet memory diamondCutFacet = IAddressesProvider(addressesProvider)
      .getDiamondCutFacet();

    cut[0] = IDiamondCut.FacetCut({
      facetAddress: address(0),
      action: IDiamondCut.FacetCutAction.Remove,
      functionSelectors: diamondCutFacet.functionSelectors
    });

    // Add the default diamondOwnershipFacet - remove after governance is set
    IAddressesProvider.Facet memory diamondOwnershipFacet = IAddressesProvider(addressesProvider)
      .getOwnershipFacet();

    cut[1] = IDiamondCut.FacetCut({
      facetAddress: address(0),
      action: IDiamondCut.FacetCutAction.Remove,
      functionSelectors: diamondOwnershipFacet.functionSelectors
    });

    address removeDiamondCutInit = IAddressesProvider(addressesProvider).getRemoveDiamondCutInit();
    bytes memory callData = abi.encodeWithSignature("setAddressesProviderInsteadOfOwner()");
    IDiamondCut(dao).diamondCut(cut, removeDiamondCutInit, callData);
  }
}
