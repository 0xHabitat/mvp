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

/**
 * @title MainDeployer - Contract which combines all deployers to provide ability to deploy the whole dao stack.
 * @dev Standard dao deployment flow:
 *      - deployGovernanceToken: deploy governance token, initial distributor and two main uniV3 pools.
 *      - deployLastMainPool: deploy main pool (governance token/weth) with 0.05% fee.
 *      - deployThreePools: deploy uniV3 pools for valid pair tokens (if supposed)
 *      - deployVotingPowerAndSignersDeciders: deploy decider signers contract, voting power manager and decider contracts.
 *      - deployDAO: finally deploy your dao, which will include all neccessary dependencies.
 * @author @roleengineer
 */
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

  /**
   * @notice Constructor function sets combination of deployer contracts.
   * @param _erc20Deployer Address of erc20 deployer (deploys erc20 governance token, initial distributor, uniV3 pools).
   * @param _deciderSignersDeployer Address of decider signers deployer.
   * @param _deciderVotingPowerDeployer Address of decider voting power deployer.
   * @param _votingPowerManagerDeployer Address of voting power manager (stake contract) deployer.
   * @param _daoDeployer Address of dao deployer (deploys diamond and initialize facets and state).
   */
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

  /**
   * @notice Deploys a erc20 token, the initial distributor contract and main uniV3 pools for it on optimism.
   * @param tokenName String represents erc20 token name.
   * @param tokenSymbol String represents erc20 token symbol.
   * @param totalSupply Sets fixed totalSupply (no minting after).
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools (with weth as a pair). First price is used if new token is token0, second if new token is token1.
   * @return Address of the new erc20 token contract.
   *         Address of the new initial distributor contract (initial distributor owner is msg.sender).
   */
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

  /**
   * @notice Deploys the last main pool (which was not deployed, because of 15mln optimism gas limit).
   * @param hbt Address of newly deployed erc20 token contract.
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools (with weth as a pair). First price is used if hbt is token0, second if hbt is token1.
   */
  function deployLastMainPool(address hbt, uint160[2] memory _sqrtPricesX96) external {
    erc20Deployer.deployLastPool(hbt, _sqrtPricesX96);
  }

  /**
   * @notice Deploys three uniV3 pools (fees: 1%, 0.3%, 0.05%).
   * @param hbt Address of newly deployed erc20 token contract.
   * @param pairAddress Address of erc20 token - new pair.
   * @param _sqrtPricesX96 An array contains two initial prices for uniV3 pools. First price is used if hbt is token0, second if hbt is token1.
   */
  function deployThreePools(
    address hbt,
    address pairAddress,
    uint160[2] memory _sqrtPricesX96
  ) external {
    erc20Deployer.deployThreePools(hbt, pairAddress, _sqrtPricesX96);
  }

  /**
   * @notice Deploys a voting power manager and decider, signers decider.
   * @dev Params _nfPositionManager, _governanceToken, _legalPairTokens are used by a voting power manager.
   *      Param _precision is used by a voting power decider.
   *      Params _dao, _daoSetter are used by a voting power decider and signers decider.
   *      Param _gnosisSafe is used by a signers decider.
   * @param _nfPositionManager UniV3 non-fungible position manager address.
   * @param _governanceToken Address of erc20 token, which is an entry point to get voting power.
   * @param _legalPairTokens Array of addresses (erc20 tokens), which are considered to be a valid pair for uniV3 pool.
   *                         UniV3 positions (erc721 tokens), which has as underlying tokens _governanceToken and one of this array
   *                         are considered to be valid for staking and getting voting power.
   * @param _precision Is used in calculations related to threshold. Threshold value
   *                   which represents threshold percentage: 50% = 0.5 * _precision.
   *                   Denominator for the threshold values. Multiplier for the threshold percentages.
   * @param _dao Address of the dao diamond contract which will be using new decider contracts as one of it's deciders.
   * @param _daoSetter Address that is allowed to set dao address one time, if it was not set at time of calling this function.

   * @param _gnosisSafe Address of the gnosis safe proxy contract, which will be used by decider signers contract as a source of decision power.
   * @return deciderSigners Address of the newly deployed decider signers contract.
   * @return deciderVotingPower Address of the newly deployed decider voting power contract.
   * @return stakeContract Address of the newly deployed voting power manager contract.
   */
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

  /**
   * @notice Deploys a DAO using EIP2535.
   * @dev See the EIP https://eips.ethereum.org/EIPS/eip-2535
   *      All arrays must be the same length and elements at the same index have to
   *      represent values related to one module.
   * @param addressesProvider Address of the contract that is a trusted source of facets and init contract addresses.
   * @param daoMetaData Metadata struct which contains 4 strings: daoName, purpose, info and socials.
   * @param msNames Array of strings that are representing module names, which are included into dao management system.
   * @param decisionTypes Array of uint8, which are representing module current decision system type.
   *                   Implemented decision system types: 2 - Voting Power, 3 - Signers.
   * @param deciders Array of contract addresses, which are representing module current decider.
   * @param votingPowerSpecificDatas Array of bytes, which are encoded voting power specific data related to module.
   *                                 Current voting power specific data is a struct that includes 4 uint256:
   *                                 thresholdForInitiator, thresholdForProposal, secondsProposalVotingPeriod, secondsProposalExecutionDelayPeriod.
   * @param signersSpecificDatas Array of bytes, which are encoded signers specific data related to module.
   * @return Address of the newly deployed dao diamond contract.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         attaching module viewer facet to the dao diamond.
   * @dev Temporary solution, probably has to/will be in ms initialization,
   * @param dao The address of the DAO diamond contract.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         initializing specific data for modules.
   * @param dao The address of the DAO diamond contract.
   * @param msNames Array of strings that are representing module names.
   * @param votingPowerSpecificDatas Array of bytes, which are encoded voting power specific data related to module.
   *                                 Current voting power specific data is a struct that includes 4 uint256:
   *                                 thresholdForInitiator, thresholdForProposal, secondsProposalVotingPeriod, secondsProposalExecutionDelayPeriod.
   * @param signersSpecificDatas Array of bytes, which are encoded signers specific data related to module.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         attaching module manager facet to the dao diamond.
   *         Enable moduleManager.
   * @param dao The address of the DAO diamond contract.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         attaching governance facet to the dao diamond.
   *         Enable governance module.
   * @param dao The address of the DAO diamond contract.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         attaching treasury actions and callback facets to the dao diamond.
   *         Enable treasury module.
   * @param dao The address of the DAO diamond contract.
   */
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

  /**
   * @notice Internal function that is doing diamond cut:
   *         removing diamondCut and ownership facets from the dao diamond.
   * @dev Temporary solution, later edit with better experience (not having them from the beginning).
   * @param dao The address of the DAO diamond contract.
   */
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
