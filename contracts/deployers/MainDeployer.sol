// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

interface IDAOViewer {
  function getDAOAddressesProvider() external view returns(address);
}

interface ISetVotingPowerHolder {
  function setVotingPowerHolder(address _votingPowerHolder) external;
}

interface IERC20Deployer {
  function deployERC20InitialDistributorMainPools(
    string memory tokenName,
    string memory tokenSymbol,
    uint256 totalSupply,
    uint160[2] memory _sqrtPricesX96
  ) external returns(address, address);

  function deployLastPool(
    address hbt,
    uint160[2] memory _sqrtPricesX96
  ) external;

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
  ) external returns(address);
}

interface IDeciderSignersDeployer {
  function deployDeciderSigners(
    address _dao,
    address _daoSetter,
    address _gnosisSafe
  ) external returns(address);
}

interface IVotingPowerManagerDeployer {
  function deployVotingPowerManagerERC20UniV3(
    address _nfPositionManager,
    address _governanceToken,
    address[] memory _legalPairTokens
  ) external returns(address);
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

  function deployDAOMS5(
    address addressesProvider,
    DAOMeta memory daoMetaData,
    DecisionType[] memory decisionTypes,
    address[] memory deciders
  ) external returns(address);
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
  ) external returns(address, address) {
    (address govToken, address distributor) = erc20Deployer.deployERC20InitialDistributorMainPools(
      tokenName,
      tokenSymbol,
      totalSupply,
      _sqrtPricesX96
    );
    return (govToken, distributor);
  }

  function deployLastMainPool(
    address hbt,
    uint160[2] memory _sqrtPricesX96
  ) external {
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
  ) external returns(address deciderSigners, address deciderVotingPower, address stakeContract) {

    deciderSigners = deciderSignersDeployer.deployDeciderSigners(
      _dao,
      _daoSetter,
      _gnosisSafe
    );

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

  function deployDAOMS5T(
    address addressesProvider,
    IDAODeploer.DAOMeta memory daoMetaData,
    IDAODeploer.DecisionType[] memory decisionTypes,
    address[] memory deciders,
    bytes memory treasuryVotingPowerSpecificData,
    bytes memory treasurySignersSpecificData
  ) external returns(address) {
    address dao = daoDeployer.deployDAOMS5(
      addressesProvider,
      daoMetaData,
      decisionTypes,
      deciders
    );
    makeTreasuryCut(
      dao,
      treasuryVotingPowerSpecificData,
      treasurySignersSpecificData
    );
    IOwnership(dao).transferOwnership(msg.sender);
    return dao;
  }

  function makeTreasuryCut(
    address dao,
    bytes memory treasuryVotingPowerSpecificData,
    bytes memory treasurySignersSpecificData
  ) internal {
    // make treasury cut
    address addressesProvider = IDAOViewer(dao).getDAOAddressesProvider();
    IDiamondCut.FacetCut[] memory treasuryCut = new IDiamondCut.FacetCut[](4);
    // Add treasury actions facet
    IAddressesProvider.Facet memory treasuryActionsFacet = IAddressesProvider(addressesProvider).getTreasuryActionsFacet();

    treasuryCut[0] = IDiamondCut.FacetCut({
      facetAddress: treasuryActionsFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: treasuryActionsFacet.functionSelectors
    });

    // Add treasury viewer facet
    IAddressesProvider.Facet memory treasuryViewerFacet = IAddressesProvider(addressesProvider).getTreasuryViewerFacet();

    treasuryCut[1] = IDiamondCut.FacetCut({
      facetAddress: treasuryViewerFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: treasuryViewerFacet.functionSelectors
    });

    // Add the treasury default callback facet
    IAddressesProvider.Facet memory treasuryDefaultCallbackFacet = IAddressesProvider(addressesProvider).getTreasuryDefaultCallbackHandlerFacet();

    treasuryCut[2] = IDiamondCut.FacetCut({
      facetAddress: treasuryDefaultCallbackFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: treasuryDefaultCallbackFacet.functionSelectors
    });

    // add voting power specific data facet
    IAddressesProvider.Facet memory votingPowerSpecificDataFacet = IAddressesProvider(addressesProvider).getVotingPowerSpecificDataFacet();

    treasuryCut[3] = IDiamondCut.FacetCut({
      facetAddress: votingPowerSpecificDataFacet.facetAddress,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: votingPowerSpecificDataFacet.functionSelectors
    });

    address treasuryInit = IAddressesProvider(addressesProvider).getTreasuryInit();
    bytes memory treasuryCallData = abi.encodeWithSignature(
      "initTreasuryVotingPowerAndSignersSpecificData(bytes,bytes)",
      treasuryVotingPowerSpecificData,
      treasurySignersSpecificData
    );
    IDiamondCut(dao).diamondCut(treasuryCut, treasuryInit, treasuryCallData);
  }
}
