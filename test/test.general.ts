import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import * as helpers from '@nomicfoundation/hardhat-network-helpers';
import habitatABI from '../habitatDiamondABI.json';
import { deployDAO } from '../scripts/deployDAO';
import { getContractsForUniV3, getWETH } from './helpers/getContractsForUniV3';

/*
initParams.json are hardcoded
TODO automate
*/

describe('HabitatDiamond', function () {
  async function deployDAOFixture() {
    const accounts = await ethers.getSigners();
    const signer = accounts[0];
    const [daoAddress, initialDistributorAddress] = await deployDAO();
    const habitatDiamond = new ethers.Contract(daoAddress, habitatABI, signer);
    const initialDistributor = await ethers.getContractAt(
      'InitialDistributorAbleToStake',
      initialDistributorAddress,
      signer
    );
    const deciderVotingPowerAddress = await habitatDiamond.getModuleDecider('treasury');
    const deciderVotingPower = await ethers.getContractAt(
      'DeciderVotingPower',
      deciderVotingPowerAddress
    );
    const deciderSignersAddress = await habitatDiamond.getModuleDecider('moduleManager');
    const deciderSigners = await ethers.getContractAt('DeciderSigners', deciderSignersAddress);
    const stakeContractAddress = await deciderVotingPower.getVotingPowerManager();
    const stakeERC20Contract = await ethers.getContractAt(
      'StakeContractERC20UniV3',
      stakeContractAddress,
      signer
    );
    const addressesProviderAddress = await habitatDiamond.getAddressesProvider();
    const addressesProvider = await ethers.getContractAt(
      'AddressesProvider',
      addressesProviderAddress,
      signer
    );
    const addresses = accounts.map((val: any) => {
      return val.address;
    });
    return {
      habitatDiamond,
      initialDistributor,
      deciderVotingPower,
      stakeERC20Contract,
      deciderSigners,
      addressesProvider,
      accounts,
      addresses,
    };
  }

  async function deployDAOAndDistributeFixture() {
    const {
      habitatDiamond,
      initialDistributor,
      deciderVotingPower,
      stakeERC20Contract,
      deciderSigners,
      addressesProvider,
      accounts,
      addresses,
    } = await helpers.loadFixture(deployDAOFixture);
    // paste distribute logic
    const hbtAddress = await stakeERC20Contract.governanceToken();
    const hbtToken = await ethers.getContractAt('HBT', hbtAddress);
    const hbtTotalSupply = await hbtToken.totalSupply();
    let tx = await initialDistributor.setStakeERC20Contract(stakeERC20Contract.address);
    await tx.wait();
    const numberOfAddresses = ethers.BigNumber.from(addresses.length);
    const halfOfTokens = hbtTotalSupply.div(2);
    const shareOfHalfOfTokens = halfOfTokens.div(numberOfAddresses);
    // distribute tokens directly
    tx = await initialDistributor.distributeMultiple(
      addresses,
      Array(addresses.length).fill(shareOfHalfOfTokens)
    );
    await tx.wait();
    // stake tokens in favor of addresses
    tx = await initialDistributor.stakeTokensInFavorOfMultipleAddresses(
      addresses,
      Array(addresses.length).fill(shareOfHalfOfTokens),
      halfOfTokens
    );
    await tx.wait();
    // let's fund DAO treasury with some ETH and WETH
    const sponsor = accounts[0];
    const weth = getWETH(sponsor);
    tx = await weth.deposit({ value: ethers.constants.WeiPerEther.mul(5) });
    await tx.wait();
    tx = await weth.transfer(habitatDiamond.address, ethers.constants.WeiPerEther.mul(5));
    await tx.wait();
    const ethTranfer = {
      to: habitatDiamond.address,
      value: ethers.utils.parseEther('5'),
    };
    tx = await sponsor.sendTransaction(ethTranfer);
    await tx.wait();

    return {
      habitatDiamond,
      hbtToken,
      stakeERC20Contract,
      deciderVotingPower,
      deciderSigners,
      addressesProvider,
      accounts,
      addresses,
      weth,
    };
  }

  async function deployDAOAndDistributeAndVPEnoughForGovernanceFixture() {
    const {
      habitatDiamond,
      deciderVotingPower,
      deciderSigners,
      addressesProvider,
      accounts,
      addresses,
    } = await helpers.loadFixture(deployDAOAndDistributeFixture);
    // let's give addresses[0] enough voting power to create governance proposals
    // by delegating from addresses[9]
    const tx = await deciderVotingPower.connect(accounts[9]).delegateVotingPower(addresses[0]);
    await tx.wait();

    // let's fund gnosisSafe with some ETH
    const gnosisSafe = await deciderSigners.gnosisSafe();
    const sponsor = accounts[7];
    const ethTranfer = {
      to: gnosisSafe,
      value: ethers.utils.parseEther('5'),
    };
    tx = await sponsor.sendTransaction(ethTranfer);
    await tx.wait();

    return {
      habitatDiamond,
      deciderVotingPower,
      deciderSigners,
      addressesProvider,
      accounts,
      addresses,
    };
  }

  it('VotingPower/ERC20: should distribute tokens', async function () {
    const { initialDistributor, deciderVotingPower, stakeERC20Contract, addresses } =
      await helpers.loadFixture(deployDAOFixture);
    this.timeout(0);
    const hbtAddress = await stakeERC20Contract.governanceToken();
    const hbtToken = await ethers.getContractAt('HBT', hbtAddress);
    const hbtTotalSupply = await hbtToken.totalSupply();
    let initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply);

    let stakeContractBalance = await hbtToken.balanceOf(stakeERC20Contract.address);
    assert(stakeContractBalance.isZero(), 'stake contract at this point must be empty');

    let tx = await initialDistributor.setStakeERC20Contract(stakeERC20Contract.address);
    await tx.wait();
    // distribute tokens directly
    const numberOfAddresses = ethers.BigNumber.from(addresses.length);
    const halfOfTokens = hbtTotalSupply.div(2);
    const shareOfHalfOfTokens = halfOfTokens.div(numberOfAddresses);
    tx = await initialDistributor.distributeMultiple(
      addresses,
      Array(addresses.length).fill(shareOfHalfOfTokens)
    );
    await tx.wait();
    for (let i = 0; i < addresses.length; i++) {
      const balance = await hbtToken.balanceOf(addresses[i]);
      expect(balance).to.eq(shareOfHalfOfTokens);
    }
    initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    expect(initialDistributorBalance).to.eq(hbtTotalSupply.sub(halfOfTokens));
    // stake tokens in favor of addresses
    tx = await initialDistributor.stakeTokensInFavorOfMultipleAddresses(
      addresses,
      Array(addresses.length).fill(shareOfHalfOfTokens),
      halfOfTokens
    );
    await tx.wait();

    initialDistributorBalance = await hbtToken.balanceOf(initialDistributor.address);
    assert(initialDistributorBalance.isZero(), 'initial distributor at this point must be empty');

    stakeContractBalance = await hbtToken.balanceOf(stakeERC20Contract.address);
    expect(stakeContractBalance).to.eq(halfOfTokens);

    for (let i = 0; i < addresses.length; i++) {
      // first check stake contract effects
      const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(
        addresses[i]
      );
      expect(stakedBalance).to.eq(shareOfHalfOfTokens);
      // second check dao contract effects
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPower).to.eq(stakedBalance);
    }
  });

  it('VotingPower/ERC20Staking: should be able to stake/unstake governance token', async function () {
    const { hbtToken, stakeERC20Contract, deciderVotingPower, accounts, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeFixture);
    const amountToStakeUnstake = await hbtToken.balanceOf(addresses[0]);
    // when stake/unstake totalAmountOfVotingPower increase/decrease
    const totalAmountOfVotingPowerBeforeStaking =
      await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerBeforeStaking.gt(0)).to.be.true;
    // should stake
    for (let i = 1; i < addresses.length; i++) {
      let tokenBalance = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalance).eq(amountToStakeUnstake);
      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      const hbtTokenNewSigner = hbtToken.connect(accounts[i]);
      // first give allowance to stake contract
      let tx = await hbtTokenNewSigner.approve(stakeERC20Contract.address, tokenBalance);
      await tx.wait();
      const allowedAmount = await hbtToken.allowance(addresses[i], stakeERC20Contract.address);
      expect(allowedAmount).to.eq(tokenBalance);
      // second stake
      tx = await stakeERC20ContractNewSigner.stakeGovToken(amountToStakeUnstake);
      await tx.wait();
      // confirm effects
      tokenBalance = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalance.isZero()).to.be.true;
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(
        addresses[i]
      );
      expect(stakedERC20GovTokenBalance.gte(amountToStakeUnstake)).to.be.true;
      const currentTotalAmountOfVotingPower =
        await deciderVotingPower.getTotalAmountOfVotingPower();
      expect(currentTotalAmountOfVotingPower).to.eq(
        totalAmountOfVotingPowerBeforeStaking.add(amountToStakeUnstake.mul(i))
      );
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPower.gte(amountToStakeUnstake)).to.be.true;
    }
    // should unstake
    const totalAmountOfVotingPowerAfterStaking =
      await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking.gt(0)).to.be.true;
    for (let i = 1; i < addresses.length; i++) {
      const votingPower = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      const stakedERC20GovTokenBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(
        addresses[i]
      );
      const tokenBalance = await hbtToken.balanceOf(addresses[i]);

      const stakeERC20ContractNewSigner = stakeERC20Contract.connect(accounts[i]);
      // first check if able to unstake
      const unstakeTimestamp = await deciderVotingPower.getTimestampToUnstake(addresses[i]);
      // no voting happened (rare case) must be 0
      expect(unstakeTimestamp.isZero()).to.be.true;
      // majority of cases we take current block timestamp
      const currentBlock = await ethers.provider.getBlock('latest');
      // if not true staker must wait
      expect(unstakeTimestamp.lte(currentBlock.timestamp)).to.be.true;

      // second unstake
      const tx = await stakeERC20ContractNewSigner.unstakeGovToken(amountToStakeUnstake);
      await tx.wait();

      // confirm effects
      const votingPowerAfterUnstake = await deciderVotingPower.getVoterVotingPower(addresses[i]);
      expect(votingPowerAfterUnstake).eq(votingPower.sub(amountToStakeUnstake));
      const stakedERC20GovTokenBalanceAfterUnstake =
        await stakeERC20Contract.getStakedBalanceOfGovernanceToken(addresses[i]);
      expect(stakedERC20GovTokenBalanceAfterUnstake).eq(
        stakedERC20GovTokenBalance.sub(amountToStakeUnstake)
      );
      const tokenBalanceAfterUnstake = await hbtToken.balanceOf(addresses[i]);
      expect(tokenBalanceAfterUnstake).eq(tokenBalance.add(amountToStakeUnstake));
    }
  });

  it('VotingPower/UNIV3Staking: should be able to stake/unstake NFT position', async function () {
    const { hbtToken, stakeERC20Contract, deciderVotingPower, accounts } =
      await helpers.loadFixture(deployDAOAndDistributeFixture);
    const newSigner = accounts[2];
    const hbtTokenNewSigner = hbtToken.connect(newSigner);
    const stakeERC20ContractNewSigner = stakeERC20Contract.connect(newSigner);
    const fee = 3000;
    const tickSpacing = 60;
    const { weth, nfPositionManager, pool } = getContractsForUniV3(
      hbtToken.address,
      fee,
      newSigner
    );
    // first provide liquidity
    // prepare mintParams
    const block = await ethers.provider.getBlock('latest');
    const isHBTToken0 = ethers.BigNumber.from(hbtToken.address).lt(
      ethers.BigNumber.from(weth.address)
    );
    const slot0 = await pool.slot0();

    const tickLower = slot0.tick - (slot0.tick % tickSpacing);
    const tickUpper = tickLower + tickSpacing;
    const mintParams = {
      token0: isHBTToken0 ? hbtToken.address : weth.address,
      token1: isHBTToken0 ? weth.address : hbtToken.address,
      fee: 3000,
      tickLower,
      tickUpper,
      amount0Desired: isHBTToken0
        ? ethers.constants.WeiPerEther.mul(10000)
        : ethers.constants.WeiPerEther.mul(5),
      amount1Desired: isHBTToken0
        ? ethers.constants.WeiPerEther.mul(5)
        : ethers.constants.WeiPerEther.mul(10000),
      amount0Min: 0,
      amount1Min: 0,
      recipient: newSigner.address,
      deadline: block.timestamp + 100000,
    };

    // convert ETH to WETH and give approvals for nfPositionManager
    let tx = await weth.deposit({ value: ethers.constants.WeiPerEther.mul(5) });
    await tx.wait();
    const wethBalance = await weth.balanceOf(newSigner.address);
    //expect(wethBalance).to.eq(ethers.constants.WeiPerEther.mul(5));
    // above line is commented, because loadFixture doesn't do exactly what it declares to do (snapshot is not about the whole state)
    // you can uncomment, but have to rerun node everytime you run tests
    tx = await weth.approve(nfPositionManager.address, ethers.constants.WeiPerEther.mul(5));
    await tx.wait();
    const wethAllowedAmount = await weth.allowance(newSigner.address, nfPositionManager.address);
    //expect(wethAllowedAmount).to.eq(wethBalance);

    tx = await hbtTokenNewSigner.approve(
      nfPositionManager.address,
      ethers.constants.WeiPerEther.mul(10000)
    );
    await tx.wait();
    const habitatAllowedAmount = await hbtTokenNewSigner.allowance(
      newSigner.address,
      nfPositionManager.address
    );
    expect(habitatAllowedAmount).to.eq(ethers.constants.WeiPerEther.mul(10000));

    // provide liquidity = mint NFTposition
    const tokenId = (await nfPositionManager.callStatic.mint(mintParams))[0];
    tx = await nfPositionManager.mint(mintParams);
    await tx.wait();
    const ownerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(ownerOfNFTposition).to.eq(newSigner.address);

    // second stake NFTpositions
    // first approve = make stake contract operator
    tx = await nfPositionManager.approve(stakeERC20Contract.address, tokenId);
    await tx.wait();
    const position = await nfPositionManager.positions(tokenId);
    expect(position.operator).to.eq(stakeERC20Contract.address);
    expect(position.token0).to.eq(isHBTToken0 ? hbtToken.address : weth.address);
    expect(position.token1).to.eq(isHBTToken0 ? weth.address : hbtToken.address);

    // stake NFTposition
    const votingPowerBeforeStake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    const totalAmountOfVotingPowerBeforeStaking =
      await deciderVotingPower.getTotalAmountOfVotingPower();

    tx = await stakeERC20ContractNewSigner.stakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    let newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(stakeERC20ContractNewSigner.address);
    let isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(
      newSigner.address,
      tokenId
    );
    expect(isStakedByHolder).to.be.true;
    // maybe write pure function that returns the amount without staking?
    const amountOfVotingPowerForNFT = await stakeERC20Contract.getAmountOfVotingPowerForNFTPosition(
      tokenId
    );
    const votingPowerAfterStake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterStake).to.eq(votingPowerBeforeStake.add(amountOfVotingPowerForNFT));
    const totalAmountOfVotingPowerAfterStaking =
      await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterStaking).to.eq(
      totalAmountOfVotingPowerBeforeStaking.add(amountOfVotingPowerForNFT)
    );

    // unstake nft position
    const unstakeTimestamp = await deciderVotingPower.getTimestampToUnstake(newSigner.address);
    // no voting happened (rare case) must be 0
    expect(unstakeTimestamp.isZero()).to.be.true;
    tx = await stakeERC20ContractNewSigner.unstakeUniV3NFTPosition(tokenId);
    await tx.wait();
    // confirm effects
    const totalAmountOfVotingPowerAfterUnstake =
      await deciderVotingPower.getTotalAmountOfVotingPower();
    expect(totalAmountOfVotingPowerAfterUnstake).to.eq(totalAmountOfVotingPowerBeforeStaking);
    const votingPowerAfterUnstake = await deciderVotingPower.getVoterVotingPower(newSigner.address);
    expect(votingPowerAfterUnstake).to.eq(votingPowerBeforeStake);
    isStakedByHolder = await stakeERC20Contract.nftPositionIsStakedByHolder(
      newSigner.address,
      tokenId
    );
    expect(isStakedByHolder).to.be.false;
    newOwnerOfNFTposition = await nfPositionManager.ownerOf(tokenId);
    expect(newOwnerOfNFTposition).to.eq(newSigner.address);
  });

  it('VotingPower/Delegation: should be able to delegate/undelegate', async function () {
    const { deciderVotingPower, accounts } = await helpers.loadFixture(
      deployDAOAndDistributeFixture
    );
    const delegator = accounts[1];
    const deciderVotingPowerDelegator = deciderVotingPower.connect(delegator);
    const delegatee = accounts[2];
    const delegatorVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(
      delegator.address
    );
    expect(delegatorVotingPowerBefore.gt(0)).to.be.true;
    const delegateeVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(
      delegatee.address
    );
    // delegate
    let tx = await deciderVotingPowerDelegator.delegateVotingPower(delegatee.address);
    await tx.wait();
    const delegatorVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(
      delegator.address
    );
    expect(delegatorVotingPowerAfter.isZero()).to.be.true;
    const delegateeVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(
      delegatee.address
    );
    expect(delegateeVotingPowerAfter).to.eq(
      delegateeVotingPowerBefore.add(delegatorVotingPowerBefore)
    );
    const delegateeCorrect = await deciderVotingPower.getDelegatee(delegator.address);
    expect(delegateeCorrect).to.eq(delegatee.address);
    const delegatedVotingPower = await deciderVotingPower.getAmountOfDelegatedVotingPower(
      delegator.address
    );
    expect(delegatedVotingPower).to.eq(delegatorVotingPowerBefore);
    // undelegate
    tx = await deciderVotingPowerDelegator.undelegateVotingPower();
    await tx.wait();
    const delegatorVotingPowerUndelegated = await deciderVotingPower.getVoterVotingPower(
      delegator.address
    );
    expect(delegatorVotingPowerUndelegated).to.eq(delegatorVotingPowerBefore);
    const delegateeVotingPowerUndelegated = await deciderVotingPower.getVoterVotingPower(
      delegatee.address
    );
    expect(delegateeVotingPowerUndelegated).to.eq(delegateeVotingPowerBefore);
  });

  it('VotingPower/Treasury module: should be able to create treasury proposal', async function () {
    const {
      habitatDiamond,
      hbtToken,
      stakeERC20Contract,
      deciderVotingPower,
      accounts,
      addresses,
      weth,
    } = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const five = ethers.constants.WeiPerEther.mul(5);
    // first lets make voting power 0 and try to create treasury proposal
    const unstaker = accounts[1];
    const beneficiar = addresses[3];
    const thresholdForInitiatorNumerator = await habitatDiamond.thresholdForInitiatorNumerator(
      'treasury'
    );
    expect(
      await deciderVotingPower.isEnoughVotingPower(unstaker.address, thresholdForInitiatorNumerator)
    ).to.be.true;
    const stakedBalance = await stakeERC20Contract.getStakedBalanceOfGovernanceToken(
      unstaker.address
    );
    const stakeERC20ContractUnstaker = stakeERC20Contract.connect(unstaker);
    const habitatDiamondUnstaker = habitatDiamond.connect(unstaker);
    const tx = await stakeERC20ContractUnstaker.unstakeGovToken(stakedBalance);
    await tx.wait();
    const unstakerVotingPower = await deciderVotingPower.getVoterVotingPower(unstaker.address);
    expect(unstakerVotingPower.isZero()).to.be.true;
    expect(
      await deciderVotingPower.isEnoughVotingPower(unstaker.address, thresholdForInitiatorNumerator)
    ).to.be.false;
    await expect(
      habitatDiamondUnstaker.createTreasuryProposal(unstaker.address, five, '0x')
    ).to.be.revertedWith('Not enough voting power to create proposal.');

    // second lets try to create a proposal that is calling diamond itself
    await expect(
      habitatDiamond.createTreasuryProposal(habitatDiamond.address, '0x0', '0x11223344')
    ).to.be.revertedWith('Not a treasury proposal.');

    // third lets try create a proposal to transfer HBT tokens from treasury
    let callData = hbtToken.interface.encodeFunctionData('transfer', [beneficiar, five.mul(1000)]);
    const proposalId = await habitatDiamond.callStatic.createTreasuryProposal(
      hbtToken.address,
      '0x0',
      callData
    );
    expect(proposalId).to.eq(ethers.constants.One);

    // lets create proposal to transfer ETH
    const treasuryExecutionDelay = await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP(
      'treasury'
    );
    const treasuryVotingPeriod = await habitatDiamond.getSecondsProposalVotingPeriod('treasury');
    const proposalIDToTransferETH = await habitatDiamond.callStatic.createTreasuryProposal(
      beneficiar,
      five,
      '0x'
    );
    let currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(beneficiar, five, '0x'))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('treasury', proposalIDToTransferETH);

    let proposal = await habitatDiamond.getModuleProposal('treasury', proposalIDToTransferETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(beneficiar);
    expect(proposal.value).to.eq(five);
    expect(proposal.callData).to.eq('0x');
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.be.closeTo(
      treasuryVotingPeriod.add(currentBlock.timestamp).add(treasuryExecutionDelay),
      3
    );

    // lets create proposal to transfer WETH
    callData = weth.interface.encodeFunctionData('transfer', [beneficiar, five]);
    const proposalIDToTransferWETH = (await habitatDiamond.getModuleProposalsCount('treasury')).add(
      1
    );
    currentBlock = await ethers.provider.getBlock('latest');
    await expect(habitatDiamond.createTreasuryProposal(weth.address, '0x0', callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('treasury', proposalIDToTransferWETH);

    proposal = await habitatDiamond.getModuleProposal('treasury', proposalIDToTransferWETH);
    expect(proposal.proposalAccepted).to.be.false;
    expect(proposal.destinationAddress).to.eq(weth.address);
    expect(proposal.value.isZero()).to.be.true;
    expect(proposal.callData).to.eq(callData);
    expect(proposal.proposalExecuted).to.be.false;
    expect(proposal.executionTimestamp).to.be.closeTo(
      treasuryVotingPeriod.add(currentBlock.timestamp).add(treasuryExecutionDelay),
      3
    );
  });

  it('VotingPower/Treasury module: should be able to decide on treasury proposal', async function () {
    const {
      habitatDiamond,
      hbtToken,
      stakeERC20Contract,
      deciderVotingPower,
      accounts,
      addresses,
    } = await helpers.loadFixture(deployDAOAndDistributeFixture);
    const five = ethers.constants.WeiPerEther.mul(5);
    const beneficiar = addresses[3];
    // first lets create treasury proposal
    const proposalID = (await habitatDiamond.getModuleProposalsCount('treasury')).add(1);
    let tx = await habitatDiamond.createTreasuryProposal(beneficiar, five, '0x');
    await tx.wait();
    // make sure that treasury decisionType is votingPowerERC20
    const decisionType = await habitatDiamond.getModuleDecisionType('treasury');
    expect(decisionType).to.eq(2);
    // lets find our proposalId in active voting
    let activeVotingProposalIds = await habitatDiamond.getModuleActiveProposalsIds('treasury');
    expect(activeVotingProposalIds.some((id: any) => id.eq(proposalID))).to.be.true;
    // the initiator already voted
    expect(await deciderVotingPower.isHolderVotedForProposal('treasury', proposalID, addresses[0]))
      .to.be.true;
    const initiatorVotingPower = await deciderVotingPower.getVoterVotingPower(accounts[0].address);
    let votesYes = await deciderVotingPower.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower);

    // make sure voting started
    expect(await deciderVotingPower.isVotingForProposalStarted('treasury', proposalID)).to.be.true;
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'treasury',
      proposalID
    );
    const currentBlock = await ethers.provider.getBlock('latest');
    expect(votingDeadline.gt(currentBlock.timestamp)).to.be.true;

    // lets decide
    // lets decide on non-exist proposal
    await expect(habitatDiamond.decideOnTreasuryProposal('0x12', true)).to.be.revertedWith(
      'No voting rn.'
    );
    // lets decide second time
    await expect(habitatDiamond.decideOnTreasuryProposal(proposalID, true)).to.be.revertedWith(
      'Already voted.'
    );
    // lets stake more govTokens, get more votingPower and decide again
    const balance = await hbtToken.balanceOf(addresses[0]);
    tx = await hbtToken.approve(stakeERC20Contract.address, balance);
    await tx.wait();
    tx = await stakeERC20Contract.stakeGovToken(balance);
    await tx.wait();
    tx = await habitatDiamond.decideOnTreasuryProposal(proposalID, true);
    await tx.wait();
    votesYes = await deciderVotingPower.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes).to.eq(initiatorVotingPower.add(balance));

    await expect(habitatDiamond.connect(accounts[1]).decideOnTreasuryProposal(proposalID, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[1], 'treasury', proposalID, true);

    const votingPowerAccount1 = await deciderVotingPower.getVoterVotingPower(accounts[1].address);
    expect(await deciderVotingPower.getProposalVotingVotesYes('treasury', proposalID)).to.eq(
      votesYes.add(votingPowerAccount1)
    );

    await expect(habitatDiamond.connect(accounts[2]).decideOnTreasuryProposal(proposalID, false))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'treasury', proposalID, false);

    const votingPowerAccount2 = await deciderVotingPower.getVoterVotingPower(accounts[2].address);
    const votesNo = await deciderVotingPower.getProposalVotingVotesNo('treasury', proposalID);
    expect(votesNo).to.eq(votingPowerAccount2);

    const thresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator(
      'treasury'
    );
    const thresholdForProposalReachedVotesYes = await deciderVotingPower.isProposalThresholdReached(
      votesYes,
      thresholdForProposalNumerator
    );
    expect(thresholdForProposalReachedVotesYes).to.be.true;

    const absoluteThresholdForProposal = await deciderVotingPower.getAbsoluteThresholdByNumerator(
      thresholdForProposalNumerator
    );
    votesYes = await deciderVotingPower.getProposalVotingVotesYes('treasury', proposalID);
    expect(absoluteThresholdForProposal.lte(votesYes)).to.be.true;

    // accept proposal
    // lets try to accept not waiting voting period
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID)).to.be.revertedWith(
      'Voting period is not ended yet.'
    );

    // lets move to timestamp when voting period is ended
    await helpers.time.increaseTo(votingDeadline);
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('treasury', proposalID, beneficiar, five, '0x');
    // confirm proposalId is removed from active
    activeVotingProposalIds = await habitatDiamond.getModuleActiveProposalsIds('treasury');
    expect(activeVotingProposalIds.some((id: any) => id.eq(proposalID))).to.be.false;
    // confirm proposal voting was removed
    votesYes = await deciderVotingPower.getProposalVotingVotesYes('treasury', proposalID);
    expect(votesYes.isZero()).to.be.true;
    // TODO also missed acceptedProposals view func

    // execute proposal
    // lets try to execute not waiting delay period
    await expect(habitatDiamond.executeTreasuryProposal(proposalID)).to.be.revertedWith(
      'Wait until proposal delay time is expired.'
    );

    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('treasury', proposalID);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    const beneficiarETHBalanceBefore = await ethers.provider.getBalance(beneficiar);
    const habitatDAOETHBalanceBefore = await ethers.provider.getBalance(habitatDiamond.address);
    // let execute
    await expect(habitatDiamond.executeTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('treasury', proposalID);

    // confirm receiving eth
    const beneficiarETHBalanceAfter = await ethers.provider.getBalance(beneficiar);
    expect(beneficiarETHBalanceBefore.add(five)).to.eq(beneficiarETHBalanceAfter);
    const habitatDAOETHBalanceAfter = await ethers.provider.getBalance(habitatDiamond.address);
    expect(habitatDAOETHBalanceBefore.sub(five)).to.eq(habitatDAOETHBalanceAfter);
    // TODO create proposal to transfer WETH and vote no to reject
  });

  it('Governance module(VP): test changeThresholdForInitiator governance method', async function () {
    const { habitatDiamond, deciderVotingPower, accounts, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeFixture
    );
    const thresholdForInitiatorGovernanceNumerator =
      await habitatDiamond.thresholdForInitiatorNumerator('governance');
    let allowedToInitiateGovernanceProposal = await deciderVotingPower.isEnoughVotingPower(
      addresses[0],
      thresholdForInitiatorGovernanceNumerator
    );
    expect(allowedToInitiateGovernanceProposal).to.be.false;
    // let's give addresses[0] enough voting power to create governance proposals
    // by delegating from addresses[9]
    const delegateeAmountOfVotingPowerBefore = await deciderVotingPower.getVoterVotingPower(
      addresses[0]
    );
    await deciderVotingPower.connect(accounts[9]).delegateVotingPower(addresses[0]);
    const delegateeAmountOfVotingPowerAfter = await deciderVotingPower.getVoterVotingPower(
      addresses[0]
    );
    expect(delegateeAmountOfVotingPowerBefore.mul(2)).to.eq(delegateeAmountOfVotingPowerAfter);
    allowedToInitiateGovernanceProposal = await deciderVotingPower.isEnoughVotingPower(
      addresses[0],
      thresholdForInitiatorGovernanceNumerator
    );
    expect(allowedToInitiateGovernanceProposal).to.be.true;

    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is threshold for initiator (description: "Value is the percentage (0.1% - 0.001 * 10000). The percentage helps to calculate the thresholdForInitiator by multiplying with maxAmountOfVotingPower (or with totalAmountOfVotingPower if it is more). Absolute value is used as a restriction for creating proposals (comparison: if initiator amount of votingPower is less than a value - is not able to create.")
    // testing case:
    //   Treasury module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Treasury
    //   decision process (if we increase/decrease value less/more voting power holders
    //   are able to create treasury proposals)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be changed to Voting Power by Module Manager functionality

    // this value (percentage) we try to change
    const treasuryThresholdForInitiatorNumerator =
      await habitatDiamond.thresholdForInitiatorNumerator('treasury');
    expect(treasuryThresholdForInitiatorNumerator.eq(50)).to.be.true;

    // let's prove that holder 4 is able to create treasury proposal with threshold equals 0.5%
    const tProposalId1 = await habitatDiamond
      .connect(accounts[4])
      .callStatic.createTreasuryProposal(addresses[4], 0, '0x');
    await expect(habitatDiamond.connect(accounts[4]).createTreasuryProposal(addresses[4], 0, '0x'))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('treasury', tProposalId1);

    /*
    // how are we getting decider instance?
    async function getModuleDeciderContractInstance(moduleName) {
      const deciderType = await habitatDiamond.getModuleDecisionType(moduleName);
      const deciderAddress = await habitatDiamond.getModuleDecider(moduleName);
      if (deciderType !== 2 || deciderType !== 3) return "decider is not implemented";
      const deciderABI = deciderType == 2 ? 'DeciderVotingPower' : 'DeciderSigners';
      const deciderInstance = await ethers.getContractAt(deciderABI, deciderAddress);
      return deciderInstance;
    }
    */

    // let's get absolute value of voting power
    const treasuryThresholdForInitiatorVotingPower =
      await deciderVotingPower.getAbsoluteThresholdByNumerator(
        treasuryThresholdForInitiatorNumerator
      );
    // the distribution was equal, let's see the absolute value of voting power for one holder
    const holderAmountOfVotingPower = await deciderVotingPower.getVoterVotingPower(addresses[1]);
    // ensure that current threshold is reachable by holder
    expect(holderAmountOfVotingPower.gt(treasuryThresholdForInitiatorVotingPower)).to.be.true;

    // current threshold is 0.5%, let's increase to 3% - this way current holders
    // will not be able to create treasury proposals until they will not increase
    // their voting power by staking or receiving delegated vp

    // creation of governance proposal to increase threshold:
    // changeThresholdForInitiator is 4 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(['string', 'uint256'], ['treasury', 300]);
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(4, callData);

    await expect(habitatDiamond.createGovernanceProposal(4, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    const activeGovernanceProposals = await habitatDiamond.getModuleActiveProposalsIds(
      'governance'
    );
    expect(activeGovernanceProposals).to.deep.include(proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's check that we have enough votes for proposal to be accepted
    // first we can get absolute amount of voting power that is required for
    // proposal to be accepted
    const thresholdForProposalNumerator = await habitatDiamond.thresholdForProposalNumerator(
      'governance'
    );
    const amountOfVotingPowerRequiredToAcceptGovernanceProposal =
      await deciderVotingPower.getAbsoluteThresholdByNumerator(thresholdForProposalNumerator);
    // then we are getting current amount of yes votes (skipped: if amount of votes no is more - proposal will be rejected)
    const amountOfVotesYes = await deciderVotingPower.getProposalVotingVotesYes('governance', 1);
    expect(amountOfVotesYes).to.be.at.least(amountOfVotingPowerRequiredToAcceptGovernanceProposal);

    // let's accept proposal (moving in future is required)
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );

    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface([
      'function changeThresholdForInitiator(string,uint256)',
    ]);
    const validCallData = iface.encodeFunctionData('changeThresholdForInitiator', [
      'treasury',
      300,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentTreasuryThresholdForInitiatorNumerator =
      await habitatDiamond.thresholdForInitiatorNumerator('treasury');
    expect(currentTreasuryThresholdForInitiatorNumerator.eq(300)).to.be.true;

    // CHECK EFFECTS

    // let's prove that holder 4 is not able to create treasury proposal
    // after threshold was changed from 0.5% to 3%
    await expect(
      habitatDiamond.connect(accounts[4]).createTreasuryProposal(addresses[4], 0, '0x')
    ).to.be.revertedWith('Not enough voting power to create proposal.');
  });

  it('Governance module(VP): test changeThresholdForProposal governance method', async function () {
    const { habitatDiamond, deciderVotingPower, accounts, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is threshold for proposal (description: "Value is the percentage (34% - 0.34 * 10000). The percentage helps to calculate the thresholdForProposal by multiplying with maxAmountOfVotingPower (or with totalAmountOfVotingPower if it is more). Absolute value is used as a restriction for accepting proposals (comparison: if votesYes and/or votesNo more than a value - proposal reached threshold, if votesYes more than votesNo - proposal is accepted, otherwise is rejected.)"
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less voting power
    //   is needed for yes/no votes for proposal to be accepted/rejected)
    // notice: if we try to change this value for LaunchPad
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be changed to Voting Power by Module Manager functionality

    // this value (percentage) we try to change
    const governanceThresholdForProposalNumerator =
      await habitatDiamond.thresholdForProposalNumerator('governance');
    // set in initParams and was used in deployment
    expect(governanceThresholdForProposalNumerator.eq(1000)).to.be.true;

    // let's get absolute value of voting power
    const governanceThresholdForProposalVotingPower =
      await deciderVotingPower.getAbsoluteThresholdByNumerator(
        governanceThresholdForProposalNumerator
      );
    const signerAmountOfVotingPower = await deciderVotingPower.getVoterVotingPower(addresses[0]);
    // ensure that current threshold is not reachable only by our signer,
    // because current threshold is 10%, signer has only 5% (need others votes)
    expect(signerAmountOfVotingPower.lt(governanceThresholdForProposalVotingPower)).to.be.true;

    // current threshold is 10%, let's decrease to 5% - this way our signer
    // will be able to accept governance proposals by himself
    // if others holders with more than 5% of voting power will not vote
    // against his proposals (otherwise proposals will be rejected)

    // creation of governance proposal to decrease threshold:
    // changeThresholdForProposal is 5 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint256'],
      ['governance', 500]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(5, callData);

    await expect(habitatDiamond.createGovernanceProposal(5, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    const activeGovernanceProposals = await habitatDiamond.getModuleActiveProposalsIds(
      'governance'
    );
    expect(activeGovernanceProposals).to.deep.include(proposalId);

    // let's prove that governance proposal now with 10% threshold value
    // can not be accepted by 5% votes that our signer has
    const signerVoted = await deciderVotingPower.isHolderVotedForProposal(
      'governance',
      proposalId,
      addresses[0]
    );
    expect(signerVoted).to.be.true;
    const amountOfVotesYes = await deciderVotingPower.getProposalVotingVotesYes(
      'governance',
      proposalId
    );
    const proposalThresholdReached = await deciderVotingPower.isProposalThresholdReached(
      amountOfVotesYes,
      governanceThresholdForProposalNumerator
    );
    expect(proposalThresholdReached).to.be.false;

    // let's give more votes to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's accept proposal (moving in future is required)
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );

    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface([
      'function changeThresholdForProposal(string,uint256)',
    ]);
    const validCallData = iface.encodeFunctionData('changeThresholdForProposal', [
      'governance',
      500,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceThresholdForProposalNumerator =
      await habitatDiamond.thresholdForProposalNumerator('governance');
    expect(currentGovernanceThresholdForProposalNumerator.eq(500)).to.be.true;

    // CHECK EFFECTS

    // let's prove that our signer now is able to accept governance proposals
    // by himself (as he has 5% of voting power and threshold is also 5%)
    // signer will execute proposal to change the value back to 10%
    // he resigns to have so much power inside the DAO ;)
    const anotherCallData = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint256'],
      ['governance', 1000]
    );
    const proposalID = await habitatDiamond.callStatic.createGovernanceProposal(5, anotherCallData);

    await expect(habitatDiamond.createGovernanceProposal(5, anotherCallData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalID);

    // move in time and accept
    const newVotingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalID
    );
    await helpers.time.increaseTo(newVotingDeadline);
    const newValidCallData = iface.encodeFunctionData('changeThresholdForProposal', [
      'governance',
      1000,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalID, governanceMethods, 0, newValidCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const newProposal = await habitatDiamond.getModuleProposal('governance', proposalID);
    await helpers.time.increaseTo(newProposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalID);

    // let's check that the value we wanted to change has changed again
    const newCurrentGovernanceThresholdForProposalNumerator =
      await habitatDiamond.thresholdForProposalNumerator('governance');
    expect(newCurrentGovernanceThresholdForProposalNumerator.eq(1000)).to.be.true;
  });

  it('Governance module(VP): test changeSecondsProposalVotingPeriod governance method', async function () {
    const { habitatDiamond, deciderVotingPower, accounts, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is secondsProposalVotingPeriod (description: "Value represents the time in seconds that is given for voting yes or no for proposals (no voting after expired). After proposal is created the countdown started, votingPowerHolder are able to vote. After voting period is ended the proposal can be accepted or rejected depending on the voting results."
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less time is given for
    //   voting power holders to make their decision on specific proposal)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be switched to Voting Power by Module Manager functionality

    // this value (seconds) we try to change
    const governanceSecondsProposalVotingPeriod =
      await habitatDiamond.getSecondsProposalVotingPeriod('governance');
    // was set in initParams.json
    expect(governanceSecondsProposalVotingPeriod.eq(604800)).to.be.true;

    // current voting period for governance is 7 days, let's decrease to 0 seconds
    // this way current holders will not be able to vote for proposals,
    // only initiator votes will be counted - if he has enough voting power
    // to reach proposal threshold then he is able to accept->execute proposal
    // if not the proposal can only be rejected (exception: the case where someone that has significant amount of vp and is clever enough to read and analize the mempool (looks like the case on optimism, although each tx is a block, tens of txs have same timestamp) and has the ability to put his tx in the same timestamp)
    // if there is no holder with enough voting power governance will stuck until
    // someone gets enough voting power by staking or receiving delegated vp
    // which will make no need in others to execute governance proposals

    // creation of governance proposal to decrease voting period (set 0 seconds):
    // changeSecondsProposalVotingPeriod is 6 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(['string', 'uint256'], ['governance', 0]);
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(6, callData);

    await expect(habitatDiamond.createGovernanceProposal(6, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(1, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    let isVotingEnded = await deciderVotingPower.isVotingForProposalEnded('governance', proposalId);
    expect(isVotingEnded).to.be.false;
    // let's prove that we cannot accept proposal until voting period is not ended
    // we have to wait the time in seconds (our previous value, which is 7 days)
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId)).to.be.revertedWith(
      'Voting period is not ended yet.'
    );

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    isVotingEnded = await deciderVotingPower.isVotingForProposalEnded('governance', proposalId);
    expect(isVotingEnded).to.be.true;

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface([
      'function changeSecondsProposalVotingPeriod(string,uint256)',
    ]);
    const validCallData = iface.encodeFunctionData('changeSecondsProposalVotingPeriod', [
      'governance',
      0,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    // let execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceSecondsProposalVotingPeriod =
      await habitatDiamond.getSecondsProposalVotingPeriod('governance');
    expect(currentGovernanceSecondsProposalVotingPeriod.eq(0)).to.be.true;

    // CHECK EFFECTS

    // let's prove that we don't need to jump in a future anymore to accept proposal
    // as our signer doesn't have enough vp the proposal could be only rejected
    const callData2 = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint256'],
      ['governance', 604800]
    );
    const proposalId2 = await habitatDiamond.callStatic.createGovernanceProposal(6, callData2);

    await expect(habitatDiamond.createGovernanceProposal(6, callData2))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId2);

    isVotingEnded = await deciderVotingPower.isVotingForProposalEnded('governance', proposalId2);
    expect(isVotingEnded).to.be.true;

    // let's try to decide on proposal
    await expect(
      habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId2, true)
    ).to.be.revertedWith('Voting period is ended.');

    const validCallData2 = iface.encodeFunctionData('changeSecondsProposalVotingPeriod', [
      'governance',
      604800,
    ]);
    // let's reject the proposal
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, 'ProposalRejected')
      .withArgs('governance', proposalId2, governanceMethods, 0, validCallData2);
  });

  it('Governance module(VP): test changeSecondsProposalExecutionDelayPeriodVP governance method', async function () {
    const { habitatDiamond, deciderVotingPower, accounts, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Voting Power
    // value is secondsProposalExecutionDelayPeriodVP (description: "Value represents the time in seconds that is given for a delaying execution after voting period is ended."
    // testing case:
    //   Governance module - which currently has Voting Power as decision type
    //   which after proposal will be executed will have immediate effect on Governance
    //   decision process (if we increase/decrease value more/less time is required
    //   to wait after voting is ended to be able to execute the proposal)
    // notice: if we try to change this value for Module manager
    //   which currently has Signers as decision type after proposal will be executed
    //   will not have immediate effect on Module manager decision process
    //   and only would have if it's decision type
    //   would be switched to Voting Power by Module Manager functionality

    // this value (seconds) we try to change
    const governanceSecondsProposalExecutionDelayPeriodVP =
      await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP('governance');
    // was set in initParams.json
    expect(governanceSecondsProposalExecutionDelayPeriodVP.eq(43200)).to.be.true;

    // current execution delay period for governance is 12 hours, let's decrease to 0 seconds
    // this way accepted proposals will be executed right after voting period is ended,
    // meaning that the someone who somehow gets a lot of voting power is able to
    // change the voting proportion in a last second and immediately execute proposal
    // which opens the ability for attack vectors (like flashloan attacks)

    // creation of governance proposal to decrease execution delay period (set 0 seconds):
    // changeSecondsProposalExecutionDelayPeriodVP is 7 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(['string', 'uint256'], ['governance', 0]);
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(7, callData);

    await expect(habitatDiamond.createGovernanceProposal(7, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface([
      'function changeSecondsProposalExecutionDelayPeriodVP(string,uint256)',
    ]);
    const validCallData = iface.encodeFunctionData('changeSecondsProposalExecutionDelayPeriodVP', [
      'governance',
      0,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    let acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds(
      'governance'
    );
    expect(acceptedGovernanceProposals).to.deep.include(proposalId);

    // execute the proposal
    // our value is important at this step (right after acceptance)
    // lets prove that we are not able to execute right away as our value is non-zero
    await expect(habitatDiamond.executeGovernanceProposal(proposalId)).to.be.revertedWith(
      'Wait until proposal delay time is expired.'
    );
    // let's jump into a future through our value (which is our delay in seconds)
    await helpers.time.increase(governanceSecondsProposalExecutionDelayPeriodVP);
    // we are in a future, let's try to execute
    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentGovernanceSecondsProposalExecutionDelayPeriodVP =
      await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP('governance');
    expect(currentGovernanceSecondsProposalExecutionDelayPeriodVP.eq(0)).to.be.true;

    // CHECK EFFECTS

    // let's prove that we don't need to wait any delay to execute proposals
    const callData2 = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint256'],
      ['governance', 43200]
    );
    const proposalId2 = await habitatDiamond.callStatic.createGovernanceProposal(7, callData2);

    await expect(habitatDiamond.createGovernanceProposal(7, callData2))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId2);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId2, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId2, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId2, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId2, true);

    const validCallData2 = iface.encodeFunctionData('changeSecondsProposalExecutionDelayPeriodVP', [
      'governance',
      43200,
    ]);
    // let's move in future and accept proposal
    const votingDeadline2 = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId2
    );
    await helpers.time.increaseTo(votingDeadline2);

    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId2, governanceMethods, 0, validCallData2);

    // proposal is accepted
    acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds('governance');
    expect(acceptedGovernanceProposals).to.deep.include(proposalId2);

    // now as our delay period is 0 we don't need to wait and executing right away
    await expect(habitatDiamond.executeGovernanceProposal(proposalId2))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId2);

    // let's check that the value was changed again
    const currentGovernanceSecondsProposalExecutionDelayPeriodVP2 =
      await habitatDiamond.getSecondsProposalExecutionDelayPeriodVP('governance');
    expect(currentGovernanceSecondsProposalExecutionDelayPeriodVP2.eq(43200)).to.be.true;
  });

  it('Governance module(VP): test changeSecondsProposalExecutionDelayPeriodSigners governance method', async function () {
    const { habitatDiamond, deciderVotingPower, deciderSigners, accounts, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // we try to change value of specific data of decision type Signers
    // value is changeSecondsProposalExecutionDelayPeriodSigners (description: "Value must represent the time in seconds that is given for a delaying execution after signers accepted the proposal. But our DeciderSigner is implemented in a way that it ignores this value, because we want to have a full control."
    // testing case:
    //   ModuleManager - which currently has Signers as decision type
    //   which after proposal will be executed should have immediate effect
    //   on ModuleManager decision process (if we increase/decrease value more/less
    //   time is required to wait after signers have accepted the proposal to be able
    //   to execute it, but in reality it will have no effect, because
    //   our DeciderSigner is implemented in a way it ignores this value)

    // this value (seconds) we try to change
    const moduleManagerSecondsProposalExecutionDelayPeriodSigners =
      await habitatDiamond.getSecondsProposalExecutionDelayPeriodSigners('moduleManager');
    expect(moduleManagerSecondsProposalExecutionDelayPeriodSigners.eq(0)).to.be.true;

    // current execution delay period for moduleManager is 0 seconds,
    // let's increase to 1 day this way accepted proposals shoul be executed
    // only after waiting 1 day, we have to prove that it's not gonna happen
    // the value inside dao will change, but will not have any effect on
    // moduleManager decision process

    // let's take prechanges example of moduleManager behaviour

    // block of moduleManager
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);

    const daoGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);
    // as an example let's change addressesProvider
    const addressesProviderAddress = await habitatDiamond.getAddressesProvider();
    const randomAddress = ethers.Wallet.createRandom().address;
    await daoGnosisSigner.changeAddressesProviderBatchedExecution(randomAddress);
    const currentAddressesProviderAddress = await habitatDiamond.getAddressesProvider();
    expect(currentAddressesProviderAddress).to.eq(randomAddress);
    // block of moduleManager

    // creation of governance proposal to increase execution delay period:
    // changeSecondsProposalExecutionDelayPeriodSigners is 8 action in governanceActions enum
    // callData is bytes (encoded string module name and uint256 new value)
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint256'],
      ['moduleManager', 86400]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(8, callData);

    await expect(habitatDiamond.createGovernanceProposal(8, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface([
      'function changeSecondsProposalExecutionDelayPeriodSigners(string,uint256)',
    ]);
    const validCallData = iface.encodeFunctionData(
      'changeSecondsProposalExecutionDelayPeriodSigners',
      ['moduleManager', 86400]
    );
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    const acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds(
      'governance'
    );
    expect(acceptedGovernanceProposals).to.deep.include(proposalId);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the value we wanted to change has changed
    const currentModuleManagerSecondsProposalExecutionDelayPeriodSigners =
      await habitatDiamond.getSecondsProposalExecutionDelayPeriodSigners('moduleManager');
    expect(currentModuleManagerSecondsProposalExecutionDelayPeriodSigners.eq(86400)).to.be.true;

    // CHECK EFFECTS

    // with new value effects batched txs will be not possible, let see if they are

    // as an example let's set normal addressesProvider back
    await expect(daoGnosisSigner.changeAddressesProviderBatchedExecution(addressesProviderAddress))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', 2);

    const postAddressesProviderAddress = await habitatDiamond.getAddressesProvider();
    expect(postAddressesProviderAddress).to.eq(addressesProviderAddress);
  });

  it('Governance module(VP): test changeDecisionData governance method', async function () {
    const { habitatDiamond, deciderVotingPower, deciderSigners, accounts, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // time to try out our general function for decision data
    // this function can change all previously described values in one go.
    // the main usecase is to set the whole configuration values of
    // any decision system for any module

    // testing case:
    //   ModuleManager - which currently has Signers as decision type
    //   our ModuleManager does not have any configuration data related
    //   to decision type Voting Power (because it uses Signers)
    //   let's first (can be done anytime) use ModuleManager function
    //   "switchModuleDecider" to switch ModuleManager active decision system
    //   from Signers to VotingPower and see what happens and then use changeDecisionData
    //   to set the whole configuration for VotingPower decision type for
    //   our ModuleManager and check the effects

    // current ModuleManager config for VotingPower (was not set up)
    const moduleManagerVotingPowerDecisionData = await habitatDiamond.getMSVotingPowerSpecificData(
      'moduleManager'
    );
    expect(moduleManagerVotingPowerDecisionData.thresholdForInitiator).to.eq(0);
    expect(moduleManagerVotingPowerDecisionData.thresholdForProposal).to.eq(0);
    expect(moduleManagerVotingPowerDecisionData.secondsProposalVotingPeriod).to.eq(0);
    expect(moduleManagerVotingPowerDecisionData.secondsProposalExecutionDelayPeriod).to.eq(0);

    // let's switch decider for ModuleManager

    // block of moduleManager
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);

    const daoGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);
    // prechanges value
    let moduleManagerDecider = await habitatDiamond.getModuleDecider('moduleManager');
    expect(moduleManagerDecider).to.eq(deciderSigners.address);

    await daoGnosisSigner.switchModuleDeciderBatchedExecution(
      'moduleManager',
      deciderVotingPower.address
    );
    // postchanges value
    moduleManagerDecider = await habitatDiamond.getModuleDecider('moduleManager');
    expect(moduleManagerDecider).to.eq(deciderVotingPower.address);

    // let's try to execute module manager proposal, e.g. changeAddressesProvider
    const addressesProviderAddress = await habitatDiamond.getAddressesProvider();
    const randomAddress = ethers.Wallet.createRandom().address;
    // let's try to use batched execution, because there is no initiator threshold,
    // no proposal threshold, no voting period and no execution delay.
    // meaning almost anyone can execute whatever in one go - VERY DANGEROUS
    // NEVER ALLOW THIS TO HAPPEN - ALL CONFIG VALUES MUST BE SET UP BEFORE SWITCH
    await expect(habitatDiamond.changeAddressesProviderBatchedExecution(randomAddress))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', 2);

    const currentAddressesProviderAddress = await habitatDiamond.getAddressesProvider();
    expect(currentAddressesProviderAddress).to.eq(randomAddress);

    // block of moduleManager

    // creation of governance proposal to set voting power config for ModuleManager
    // changeDecisionData is 3 action in governanceActions enum
    // callData is bytes (encoded string module name - "moduleManager";
    // and uint8 decisionType - 2; and bytes memory newDecisionData:
    // uint256 initiator threshold - 20%, uint256 proposal threshold - 50%,
    // uint256 voting period - 7days, uint256 execution delay - 1 day)
    const newDecisionData = ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'uint256', 'uint256', 'uint256'],
      [2000, 5000, 604800, 86400]
    );
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['string', 'uint8', 'bytes'],
      ['moduleManager', 2, newDecisionData]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(3, callData);

    await expect(habitatDiamond.createGovernanceProposal(3, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(['function changeDecisionData(string,uint8,bytes)']);
    const validCallData = iface.encodeFunctionData('changeDecisionData', [
      'moduleManager',
      2,
      newDecisionData,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    const acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds(
      'governance'
    );
    expect(acceptedGovernanceProposals).to.deep.include(proposalId);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // let's check that the decisionData we wanted to change has changed
    const currentModuleManagerVotingPowerDecisionData =
      await habitatDiamond.getMSVotingPowerSpecificData('moduleManager');
    expect(currentModuleManagerVotingPowerDecisionData.thresholdForInitiator).to.eq(2000);
    expect(currentModuleManagerVotingPowerDecisionData.thresholdForProposal).to.eq(5000);
    expect(currentModuleManagerVotingPowerDecisionData.secondsProposalVotingPeriod).to.eq(604800);
    expect(currentModuleManagerVotingPowerDecisionData.secondsProposalExecutionDelayPeriod).to.eq(
      86400
    );

    // CHECK EFFECTS

    // batched transaction must be reverted, because the threshold for initiator
    // is not reachable for our signer
    await expect(
      habitatDiamond.changeAddressesProviderBatchedExecution(addressesProviderAddress)
    ).to.be.revertedWith('Not enough voting power to create proposal.');
  });

  it('Governance module/Voting Power: should be able to execute updateFacet governance proposal', async function () {
    const { habitatDiamond, deciderVotingPower, addressesProvider, accounts, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // time to try out updateFacet function
    // currently we have AddressesProvider which is the only one trusted source
    // to get updates for our DAO.
    // updateFacet function gets as an input only facet address (which has to be
    // known by AddressesProvider)
    // the new facet must replace old facet (all the previous function selectors
    // must be inlcuded, which means that api must stay the same or extended
    // with new functions and only the previous functions logic can be updated)

    // testing case:
    //   we have upgraded dao viewer facet
    //   as our signer is an owner of AddressesProvider, we set new DAOViewerFacet
    //   and try to execute update through governance

    // let's first get selectors that must be included in our new facet
    const daoViewerFacet = await addressesProvider.getDAOViewerFacet();
    const oldDAOViewerAddress = daoViewerFacet.facetAddress;
    const daoViewerSelectors = daoViewerFacet.functionSelectors;

    // let's prove that selectors are included in our dao
    const oldFacetAddress = await habitatDiamond.facetAddress(daoViewerSelectors[0]);
    expect(oldFacetAddress).to.eq(oldDAOViewerAddress);
    const oldFacetSelectors = await habitatDiamond.facetFunctionSelectors(oldFacetAddress);
    expect(oldFacetSelectors).to.deep.eq(daoViewerSelectors);

    // deploy our upgraded dao viewer facet that has same selectors as old one
    // (some of the functions with new logic) and few new functions
    const DAOViewerFacetTest = await ethers.getContractFactory('DAOViewerFacetTest');
    const newDAOViewerFacet = await DAOViewerFacetTest.deploy();
    await newDAOViewerFacet.deployed();

    // as updateFacet rule said new facet must include all previous selectors
    const newSelectors = [...daoViewerSelectors];
    // added two new functions
    newSelectors.push(newDAOViewerFacet.interface.getSighash('newDAOViewerFunction1'));
    newSelectors.push(newDAOViewerFacet.interface.getSighash('newDAOViewerFunction2'));

    // let's make the facet upgrade inside our AddressesProvider,
    // by setting new address and attaching old selectors + new one
    await expect(addressesProvider.setDAOViewerFacet(newDAOViewerFacet.address, newSelectors))
      .to.emit(addressesProvider, 'DAOViewerFacetUpdated')
      .withArgs(oldDAOViewerAddress, newDAOViewerFacet.address);

    const newFacetAddress = await addressesProvider.getDAOViewerFacetAddress();
    expect(newFacetAddress).to.eq(newDAOViewerFacet.address);

    // prechanges call result of function that will change the logic
    let daoSocials = await habitatDiamond.getDAOSocials();
    expect(daoSocials).to.eq('https://0xhabitat.org/');
    // prechanges call result of function that will not change the logic
    let daoName = await habitatDiamond.getDAOName();
    expect(daoName).to.eq('HabitatDAO');

    // creation of governance proposal of facet update
    // updateFacet is 1 action in governanceActions enum
    // callData is bytes (encoded new facet address)
    const callData = ethers.utils.defaultAbiCoder.encode(['address'], [newFacetAddress]);
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(1, callData);

    await expect(habitatDiamond.createGovernanceProposal(1, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(['function updateFacet(address)']);
    const validCallData = iface.encodeFunctionData('updateFacet', [newFacetAddress]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    const acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds(
      'governance'
    );
    expect(acceptedGovernanceProposals).to.deep.include(proposalId);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // CHECK EFFECTS

    // let's prove that our old selectors now redirects the calls to new address
    const newDAOViewerFacetAddress = await habitatDiamond.facetAddress(daoViewerSelectors[0]);
    expect(newDAOViewerFacetAddress).to.eq(newFacetAddress);
    const newFacetSelectors = await habitatDiamond.facetFunctionSelectors(newDAOViewerFacetAddress);
    expect(newFacetSelectors).to.deep.eq(newSelectors);

    // postchanges call result of function that has changed the logic
    daoSocials = await habitatDiamond.getDAOSocials();
    expect(daoSocials).to.eq('new dao socials');
    // postchanges call result of function that hasn't changed the logic
    daoName = await habitatDiamond.getDAOName();
    expect(daoName).to.eq('HabitatDAO');
    // new dao functions works
    let resultOfNewFunctionCall = await newDAOViewerFacet
      .attach(habitatDiamond.address)
      .newDAOViewerFunction1();
    expect(resultOfNewFunctionCall).to.eq(256);

    resultOfNewFunctionCall = await newDAOViewerFacet
      .attach(habitatDiamond.address)
      .newDAOViewerFunction2();
    expect(resultOfNewFunctionCall).to.eq('some another new string');

    // RESET STATE of ADDRESSES PROVIDER (loadfixture does not work perfectly)
    // reset dao viewer facet
    await expect(addressesProvider.setDAOViewerFacet(oldDAOViewerAddress, daoViewerSelectors))
      .to.emit(addressesProvider, 'DAOViewerFacetUpdated')
      .withArgs(newFacetAddress, oldDAOViewerAddress);
  });

  it('Governance module/Voting Power: should be able to execute updateFacetAndState governance proposal', async function () {
    const { habitatDiamond, deciderVotingPower, addressesProvider, accounts, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our Governance module functionality
    // time to try out updateFacet function
    // currently we have AddressesProvider which is the only one trusted source
    // to get updates for our DAO.
    // updateFacetAndState function gets as an input facet address (which has to be
    // known by AddressesProvider) and the calldata for init contract (contains
    // function selector of init contract and this function input data)
    // the new facet must replace old facet (all the previous function selectors
    // must be inlcuded, which means that api must stay the same or extended
    // with new functions and only the previous functions logic can be updated)

    // testing case:
    //   we have upgraded dao viewer facet and upgraded dao init contract
    //   as our signer is an owner of AddressesProvider, we set new DAOInit
    //   and new DAOViewerFacet
    //   after that try to execute update through governance

    // deploy our upgraded dao init contract and dao viewer facet that has
    // same selectors as old one (some of the functions with new logic) and few new functions
    const DAOInitTest = await ethers.getContractFactory('DAOInitTest');
    const newDAOInit = await DAOInitTest.deploy();
    await newDAOInit.deployed();

    const DAOViewerFacetTest = await ethers.getContractFactory('DAOViewerFacetTest');
    const newDAOViewerFacet = await DAOViewerFacetTest.deploy();
    await newDAOViewerFacet.deployed();
    const signatures = Object.keys(newDAOViewerFacet.interface.functions);
    const selectors = signatures.reduce((acc: string[], val) => {
      acc.push(newDAOViewerFacet.interface.getSighash(val));
      return acc;
    }, []);

    const oldDAOInitAddress = await addressesProvider.getDAOInit();
    // let's make the dao init upgrade inside our AddressesProvider
    // important to set init first, because it will be used as init for new facet
    await expect(addressesProvider.setDAOInit(newDAOInit.address))
      .to.emit(addressesProvider, 'DAOInitUpdated')
      .withArgs(oldDAOInitAddress, newDAOInit.address);

    const newInitAddress = await addressesProvider.getDAOInit();
    expect(newInitAddress).to.eq(newDAOInit.address);

    const oldDAOViewerAddress = await addressesProvider.getDAOViewerFacetAddress();
    const oldFacet = await addressesProvider.getDAOViewerFacet();
    const oldDAOViewerSelectors = oldFacet.functionSelectors;
    // let's make the facet upgrade inside our AddressesProvider,
    // by setting new address and attaching it's selectors
    await expect(addressesProvider.setDAOViewerFacet(newDAOViewerFacet.address, selectors))
      .to.emit(addressesProvider, 'DAOViewerFacetUpdated')
      .withArgs(oldDAOViewerAddress, newDAOViewerFacet.address);

    const newFacetAddress = await addressesProvider.getDAOViewerFacetAddress();
    expect(newFacetAddress).to.eq(newDAOViewerFacet.address);

    // let's have dao instance with dao viewer interface
    const habitatDAO = newDAOViewerFacet.attach(habitatDiamond.address);

    // preupdate call result of function that reads new state
    await expect(habitatDAO.readNewDAOState()).to.be.revertedWith(
      'Diamond: Function does not exist'
    );

    // let's read the storage slot that will be written to during updateState
    const storageSlot = ethers.BigNumber.from(
      ethers.utils.id('habitat.diamond.standard.dao.storage')
    )
      .add(6)
      .toHexString();
    const valueAtSlot = await ethers.provider.getStorageAt(habitatDiamond.address, storageSlot);
    expect(valueAtSlot).to.eq('0x0000000000000000000000000000000000000000000000000000000000000000');

    // creation of governance proposal of facet update
    // updateFacetAndState is 2 action in governanceActions enum
    // callData is bytes (encoded new facet address and stateUpdate for init contract)
    const stateUpdate = newDAOInit.interface.encodeFunctionData(
      'initNewStringInDAOStorage(string)',
      ["it's our new state string"]
    );
    const callData = ethers.utils.defaultAbiCoder.encode(
      ['address', 'bytes'],
      [newFacetAddress, stateUpdate]
    );
    const proposalId = await habitatDiamond.callStatic.createGovernanceProposal(2, callData);

    await expect(habitatDiamond.createGovernanceProposal(2, callData))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('governance', proposalId);

    // let's decide on proposal to make it accepted
    await expect(habitatDiamond.connect(accounts[2]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[2], 'governance', proposalId, true);

    await expect(habitatDiamond.connect(accounts[3]).decideOnGovernanceProposal(proposalId, true))
      .to.emit(deciderVotingPower, 'Voted')
      .withArgs(addresses[3], 'governance', proposalId, true);

    // let's move in future and accept proposal
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'governance',
      proposalId
    );
    await helpers.time.increaseTo(votingDeadline);

    const governanceMethods = await habitatDiamond.getGovernanceMethods();
    const iface = new ethers.utils.Interface(['function updateFacetAndState(address,bytes)']);
    const validCallData = iface.encodeFunctionData('updateFacetAndState', [
      newFacetAddress,
      stateUpdate,
    ]);
    await expect(habitatDiamond.acceptOrRejectGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('governance', proposalId, governanceMethods, 0, validCallData);

    const acceptedGovernanceProposals = await habitatDiamond.getModuleAcceptedProposalsIds(
      'governance'
    );
    expect(acceptedGovernanceProposals).to.deep.include(proposalId);

    // execute the proposal
    // lets move to timestamp when execution delay period is ended
    const proposal = await habitatDiamond.getModuleProposal('governance', proposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);

    await expect(habitatDiamond.executeGovernanceProposal(proposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('governance', proposalId);

    // CHECK EFFECTS

    // let's prove that our old selectors now redirects the calls to new address
    const newDAOViewerFacetAddress = await habitatDiamond.facetAddress(selectors[0]);
    expect(newDAOViewerFacetAddress).to.eq(newFacetAddress);
    const newFacetSelectors = await habitatDiamond.facetFunctionSelectors(newDAOViewerFacetAddress);
    expect(newFacetSelectors).to.deep.eq(selectors);

    // postupdate call result of function that reads new state
    const newStringInDAOStorage = await habitatDAO.readNewDAOState();
    expect(newStringInDAOStorage).to.eq("it's our new state string");

    // let's read the storage slot that was written to during updateState
    const currentValueAtSlot = await ethers.provider.getStorageAt(
      habitatDiamond.address,
      storageSlot
    );
    expect(currentValueAtSlot).to.eq(
      '0x69742773206f7572206e657720737461746520737472696e6700000000000032'
    );

    // RESET STATE of ADDRESSES PROVIDER (loadfixture does not work perfectly)
    // reset dao init
    await expect(addressesProvider.setDAOInit(oldDAOInitAddress))
      .to.emit(addressesProvider, 'DAOInitUpdated')
      .withArgs(newInitAddress, oldDAOInitAddress);

    // reset dao viewer facet
    await expect(addressesProvider.setDAOViewerFacet(oldDAOViewerAddress, oldDAOViewerSelectors))
      .to.emit(addressesProvider, 'DAOViewerFacetUpdated')
      .withArgs(newFacetAddress, oldDAOViewerAddress);
  });

  it('ModuleManager/Signers: should be able to execute switchModuleDecider proposal', async function () {
    const { habitatDiamond, deciderSigners, deciderVotingPower, addresses } =
      await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our ModuleManager functionality (Decision type: Signers)
    // switchModuleDecider method
    // this method is able to switch decider for any module, e.i.
    // module was using one decider, after method execution new decision process
    // applies for a module

    // testing case:
    //   we try interesting case, we will switch decider for Treasury module
    //   from Voting Power to Signers
    //   but first we will have the case where bad actor got enough voting power
    //   to execute Treasury proposal, and he tries to withdraw all ETH from treasury
    //   and accepted the proposal and just waiting execution delay period
    //   let's see what happen with the "rug" proposal after switching the decider
    //   bad actor is our signer = accounts[0]

    // Treasury block
    let treasuryDeciderAddress = await habitatDiamond.getModuleDecider('treasury');
    expect(treasuryDeciderAddress).eq(deciderVotingPower.address);

    const daoETHBalance = await ethers.provider.getBalance(habitatDiamond.address);
    expect(daoETHBalance).to.eq(ethers.constants.WeiPerEther.mul(5));

    // bad actor initialize treasury proposal to send him all ETH
    const badProposalId = await habitatDiamond.callStatic.sendETHFromTreasuryInitProposal(
      addresses[0],
      daoETHBalance
    );
    await expect(habitatDiamond.sendETHFromTreasuryInitProposal(addresses[0], daoETHBalance))
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('treasury', badProposalId);

    // as bad actor has enough voting power, he just waits proposal period to accept
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'treasury',
      badProposalId
    );
    await helpers.time.increaseTo(votingDeadline);
    // bad actor accepts proposal
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(badProposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('treasury', badProposalId, addresses[0], daoETHBalance, '0x');
    // at this point bad actor have to wait treasury execution delay period
    // Treasury block

    // the team recognize bad behaviour and decided to intervene
    const moduleManagerDeciderAddress = await habitatDiamond.getModuleDecider('moduleManager');
    expect(deciderSigners.address).eq(moduleManagerDeciderAddress);

    // let's simulate the gnosis offchain decision process by executing from
    // gnosis safe address
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);
    const habitatDAOGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);

    // we are able to call batched tx (includes proposal creation, decision, execution stages)
    const switchProposalId =
      await habitatDAOGnosisSigner.callStatic.switchModuleDeciderInitProposal(
        'treasury',
        deciderSigners.address
      );

    // let's switch decider for our Treasury module to Signers
    await expect(
      habitatDAOGnosisSigner.switchModuleDeciderBatchedExecution('treasury', deciderSigners.address)
    )
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', switchProposalId);

    // let's prove that treasury now has another decider
    treasuryDeciderAddress = await habitatDiamond.getModuleDecider('treasury');
    expect(treasuryDeciderAddress).eq(deciderSigners.address);

    // Treasury block
    // bad actor have not noticed that we switched the decider and waits delay
    const proposal = await habitatDiamond.getModuleProposal('treasury', badProposalId);
    await helpers.time.increaseTo(proposal.executionTimestamp);
    // he finally executes his proposal
    await expect(habitatDiamond.executeTreasuryProposal(badProposalId)).to.revertedWith(
      'Decider: Proposal cannot be executed.'
    );
    // Treasury block

    // TODO as proposal data stuck forever - we need the method to clean our storage

    // let's prove that ETH is still inside dao treasury
    const daoETHBalanceNow = await ethers.provider.getBalance(habitatDiamond.address);
    expect(daoETHBalanceNow).to.eq(daoETHBalance);
  });

  it('ModuleManager/Signers: should be able to execute addNewModuleWithFacets proposal', async function () {
    const { habitatDiamond, deciderSigners, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our ModuleManager functionality (Decision type: Signers)
    // addNewModuleWithFacets method
    // this method is able to add new module with facets, e.i.
    // only adding new module and pure functionality that does not need any new storage
    // Current implementation requires careful usage with strict algorithm:
    // the decision type has to be set as Signers (can any be set, but it's mistake
    // because e.g. Voting Power requires to write values to dao storage, which better
    // could be done with ModuleManager method addNewModuleWithFacetsAndStateUpdate)
    // if planning to use different decision type - better to use method
    // addNewModuleWithFacetsAndStateUpdate or after adding with Signers decisions
    // type, Governance module has to be used to set the specific decision data
    // for this type (if required, e.i. the case for Voting Power) and only after that
    // switchModuleDecider can be called. If not using strictly algorithm above and
    // set Voting Power as a decision type as an input to this method,
    // it will have no values and anyone can make any decisions.
    // Also, the facets must be reviewed first - their implementation must include
    // LibDecisionProcess.sol same way as current modules.

    // testing case:
    //   idea is to add new module named PieceTokenDistributor (Signers), which has
    //   functionality to distribute Peace erc20 tokens by minting (does not require
    //   any dao storage, only pure functionality). Peace ERC20 totalSupply is 0,
    //   only HabitatDAO can mint. Core module method is peaceDistribution, which
    //   takes arrays of receivers and respective amounts and if proposal is
    //   executed than mints new Peace tokens using proposal distribution rule.

    // preparation work: deploy Peace token and PeaceTokenDistributorFacet
    const PeaceTest = await ethers.getContractFactory('PeaceTest');
    // put or dao address as the only minter
    const peaceToken = await PeaceTest.deploy('PeaceToken', 'Peace', habitatDiamond.address);
    await peaceToken.deployed();

    const PeaceTokenDistributorFacetTest = await ethers.getContractFactory(
      'PeaceTokenDistributorFacetTest'
    );
    const peaceDistributorFacet = await PeaceTokenDistributorFacetTest.deploy(peaceToken.address);
    await peaceDistributorFacet.deployed();
    const signatures = Object.keys(peaceDistributorFacet.interface.functions);
    const peaceDistributorFacetSelectors = signatures.reduce((acc: string[], val) => {
      acc.push(peaceDistributorFacet.interface.getSighash(val));
      return acc;
    }, []);

    // let's simulate the gnosis offchain decision process by executing from
    // gnosis safe address
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);
    const habitatDAOGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);

    // let's get our management system and check that we have 5 modules now
    let managementSystem = await habitatDiamond.getManagementSystemsHumanReadable();
    expect(managementSystem.length).eq(5);
    // let's prove that we don't have our new module
    let moduleNames = await habitatDiamond.getModuleNames();
    expect(moduleNames).to.not.include('PeaceTokenDistributor');

    // first let's try to add module which has name > 31bytes
    const newModuleParams = [
      'verylongmodulenamethatisoutofhabitatbounds',
      3,
      deciderSigners.address,
      [peaceDistributorFacet.address],
      [peaceDistributorFacetSelectors],
    ];
    const longNameProposalId =
      await habitatDAOGnosisSigner.callStatic.addNewModuleWithFacetsInitProposal(
        ...newModuleParams
      );
    // let's try to add very long name module
    await expect(habitatDAOGnosisSigner.addNewModuleWithFacetsBatchedExecution(...newModuleParams))
      .to.emit(habitatDiamond, 'ProposalExecutedWithRevert')
      .withArgs('moduleManager', longNameProposalId);
    // the proposal with long name was reverted, let's prove that new facet is not here
    const daoWithNewFacet = peaceDistributorFacet
      .attach(habitatDiamond.address)
      .connect(impersonatedGnosisSafe);
    await expect(
      daoWithNewFacet.peaceDistributionBatchedExecution(
        addresses,
        Array(addresses.length).fill(1000000)
      )
    ).to.be.revertedWith('Diamond: Function does not exist');

    // let's finally add new module and facet
    newModuleParams[0] = 'PeaceTokenDistributor';
    const proposalId = await habitatDAOGnosisSigner.callStatic.addNewModuleWithFacetsInitProposal(
      ...newModuleParams
    );
    await expect(habitatDAOGnosisSigner.addNewModuleWithFacetsBatchedExecution(...newModuleParams))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', proposalId);

    // at this point we have new module
    // let's get our management system and check that we have 6 modules now
    managementSystem = await habitatDiamond.getManagementSystemsHumanReadable();
    expect(managementSystem.length).eq(6);
    // let's prove that we have our new module
    moduleNames = await habitatDiamond.getModuleNames();
    expect(moduleNames).to.include('PeaceTokenDistributor');
    const peaceTokenDecider = await habitatDiamond.getModuleDecider('PeaceTokenDistributor');
    expect(peaceTokenDecider).to.eq(deciderSigners.address);

    // CHECK EFFECTS
    // as now we have new functionality let's execute Peace distribution
    let peaceBalance3 = await peaceToken.balanceOf(addresses[3]);
    expect(peaceBalance3).to.eq(0);
    const distributionProposalId = await daoWithNewFacet.callStatic.createPeaceDistributionProposal(
      addresses,
      Array(addresses.length).fill(1000000)
    );

    await expect(
      daoWithNewFacet.peaceDistributionBatchedExecution(
        addresses,
        Array(addresses.length).fill(1000000)
      )
    )
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('PeaceTokenDistributor', distributionProposalId);

    peaceBalance3 = await peaceToken.balanceOf(addresses[3]);
    expect(peaceBalance3).to.eq(1000000);
  });

  it('ModuleManager/Signers: should be able to execute addNewModuleWithFacetsAndStateUpdate proposal', async function () {
    const {
      habitatDiamond,
      deciderSigners,
      deciderVotingPower,
      addressesProvider,
      accounts,
      addresses,
    } = await helpers.loadFixture(deployDAOAndDistributeAndVPEnoughForGovernanceFixture);
    // testing our ModuleManager functionality (Decision type: Signers)
    // addNewModuleWithFacetsAndStateUpdate method
    // this method is able to add new module with facets + storage, e.i.
    // adding new module and functionality and also writting data to dao storage
    // The facets must be reviewed first - their implementation must include
    // LibDecisionProcess.sol same way as current modules.

    // testing case:
    //   idea is to add new module named PeaceTokenDistributor (Voting Power), which has
    //   functionality to distribute Peace erc20 tokens by minting (does not require
    //   any dao storage, only pure functionality). Peace ERC20 totalSupply is 0,
    //   only HabitatDAO can mint. Core module method is peaceDistribution, which
    //   takes arrays of receivers and respective amounts and if proposal is
    //   executed than mints new Peace tokens using proposal distribution rule.
    //   Our new module does not require any specific state inside the dao, but
    //   as decision type for PeaceTokenDistributor module will be Voting Power,
    //   which requires config written to dao storage, we use SpecificDataInit to
    //   initialize neccessary state.

    // preparation work: deploy Peace token and PeaceTokenDistributorFacet
    const PeaceTest = await ethers.getContractFactory('PeaceTest');
    // put or dao address as the only minter
    const peaceToken = await PeaceTest.deploy('PeaceToken', 'Peace', habitatDiamond.address);
    await peaceToken.deployed();

    const PeaceTokenDistributorFacetTest = await ethers.getContractFactory(
      'PeaceTokenDistributorFacetTest'
    );
    const peaceDistributorFacet = await PeaceTokenDistributorFacetTest.deploy(peaceToken.address);
    await peaceDistributorFacet.deployed();
    const signatures = Object.keys(peaceDistributorFacet.interface.functions);
    const peaceDistributorFacetSelectors = signatures.reduce((acc: string[], val) => {
      acc.push(peaceDistributorFacet.interface.getSighash(val));
      return acc;
    }, []);

    // let's simulate the gnosis offchain decision process by executing from
    // gnosis safe address
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);
    const habitatDAOGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);

    // let's get our management system and check that we have 5 modules now
    let managementSystem = await habitatDiamond.getManagementSystemsHumanReadable();
    expect(managementSystem.length).eq(5);
    // let's prove that we don't have our new module
    let moduleNames = await habitatDiamond.getModuleNames();
    expect(moduleNames).to.not.include('PeaceTokenDistributor');

    // first let's collect all params
    const specificDataInit = await addressesProvider.getSpecificDataInit();
    const iface = new ethers.utils.Interface([
      'function initVotingPowerSpecificData(string[],uint256[],uint256[],uint256[],uint256[])',
    ]);
    const initCallData = iface.encodeFunctionData('initVotingPowerSpecificData', [
      ['PeaceTokenDistributor'],
      [10],
      [100],
      [3600],
      [3600],
    ]);
    const newModuleParams = [
      'PeaceTokenDistributor',
      2,
      deciderVotingPower.address,
      [peaceDistributorFacet.address],
      [peaceDistributorFacetSelectors],
      specificDataInit,
      initCallData,
    ];
    const proposalId =
      await habitatDAOGnosisSigner.callStatic.addNewModuleWithFacetsAndStateUpdateInitProposal(
        ...newModuleParams
      );

    // let's add new module with facet and state update
    await expect(
      habitatDAOGnosisSigner.addNewModuleWithFacetsAndStateUpdateBatchedExecution(
        ...newModuleParams
      )
    )
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', proposalId);

    // at this point we have new module
    // let's get our management system and check that we have 6 modules now
    managementSystem = await habitatDiamond.getManagementSystemsHumanReadable();
    expect(managementSystem.length).eq(6);
    // let's prove that we have our new module
    moduleNames = await habitatDiamond.getModuleNames();
    expect(moduleNames).to.include('PeaceTokenDistributor');
    const peaceTokenDecider = await habitatDiamond.getModuleDecider('PeaceTokenDistributor');
    expect(peaceTokenDecider).to.eq(deciderVotingPower.address);

    // CHECK EFFECTS
    // as now we have new functionality let's execute Peace distribution
    const daoWithNewFacet = peaceDistributorFacet
      .attach(habitatDiamond.address)
      .connect(accounts[0]);
    let peaceBalance3 = await peaceToken.balanceOf(addresses[3]);
    expect(peaceBalance3).to.eq(0);
    const distributionProposalId = await daoWithNewFacet.callStatic.createPeaceDistributionProposal(
      addresses,
      Array(addresses.length).fill(1000000)
    );

    // let's create proposal to distribute peace
    await expect(
      daoWithNewFacet.createPeaceDistributionProposal(
        addresses,
        Array(addresses.length).fill(1000000)
      )
    )
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('PeaceTokenDistributor', distributionProposalId);
    // as our signer has enough voting to accept proposal, let's move in future
    const votingDeadline = await deciderVotingPower.getProposalVotingDeadlineTimestamp(
      'PeaceTokenDistributor',
      distributionProposalId
    );
    await helpers.time.increaseTo(votingDeadline);
    // let's accept
    const validCallData = peaceToken.interface.encodeFunctionData('mintPeaceMax500', [
      addresses,
      Array(addresses.length).fill(1000000),
    ]);
    await expect(daoWithNewFacet.acceptOrRejectPeaceDistributionProposal(distributionProposalId))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs(
        'PeaceTokenDistributor',
        distributionProposalId,
        peaceToken.address,
        0,
        validCallData
      );
    // let's move to timestamp when we can execute distribution proposal
    const distributionProposal = await habitatDiamond.getModuleProposal(
      'PeaceTokenDistributor',
      distributionProposalId
    );
    await helpers.time.increaseTo(distributionProposal.executionTimestamp);

    await expect(daoWithNewFacet.executePeaceDistributionProposal(distributionProposalId))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('PeaceTokenDistributor', distributionProposalId);

    peaceBalance3 = await peaceToken.balanceOf(addresses[3]);
    expect(peaceBalance3).to.eq(1000000);
  });

  it('ModuleManager/Signers: should be able to execute removeModule proposal', async function () {
    const { habitatDiamond, deciderSigners, addresses } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our ModuleManager functionality (Decision type: Signers)
    // removeModule method
    // this method is able to remove any existing module.

    // testing case:
    //   remove Treasury module
    // notice:
    //   facets are still here (not working), but not removed
    //   make sense to implement module facets as part of module

    // let's simulate the gnosis offchain decision process by executing from
    // gnosis safe address
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);
    const habitatDAOGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);

    // let's remove Treasury module
    const removeTreasuryProposalId =
      await habitatDAOGnosisSigner.callStatic.removeModuleInitProposal('treasury');

    await expect(habitatDAOGnosisSigner.removeModuleBatchedExecution('treasury'))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', removeTreasuryProposalId);

    // let's prove that Treasury module is removed
    await expect(habitatDiamond.getModuleDecider('treasury')).to.be.revertedWith(
      'Management system does not exist within DAO.'
    );
    // let's try to make treasury proposal
    await expect(
      habitatDiamond.createTreasuryProposal(addresses[0], ethers.constants.WeiPerEther, '0x')
    ).to.be.revertedWith('Management system does not exist within DAO.');
  });

  it('ModuleManager/Signers: should be able to execute changeAddressesProvider proposal', async function () {
    const { habitatDiamond, deciderSigners, accounts } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our ModuleManager functionality (Decision type: Signers)
    // changeAddressesProvider method
    // this method is able to change addresses provider
    // AddressesProvider is a trusted source of facets and init contracts that dao
    // uses on deploying stage and facets upgrades

    // testing case:
    //   change AddressesProvider to random address
    //   go through Signers onchain decision process

    const gnosisSafe = await deciderSigners.gnosisSafe();

    // first impersonate gnosis signers accounts
    const iface = new ethers.utils.Interface([
      'function getOwners() view returns(address[])',
      'function getThreshold() view returns(uint256)',
    ]);
    const gnosisInstance = new ethers.Contract(gnosisSafe, iface, accounts[0]);
    const signers = await gnosisInstance.getOwners();
    const threshold = await gnosisInstance.getThreshold();

    const impersonatedSigners = [];
    for (let i = 0; i < threshold; i++) {
      await helpers.impersonateAccount(signers[i]);
      const signer = await ethers.getSigner(signers[i]);
      impersonatedSigners.push(signer);
    }

    const newAddressesProvider = ethers.Wallet.createRandom().address;
    // let's initiate proposal to change addresses provider
    const nextMMProposal = (await habitatDiamond.getModuleProposalsCount('moduleManager')).add(1);
    await expect(
      habitatDiamond
        .connect(impersonatedSigners[0])
        .changeAddressesProviderInitProposal(newAddressesProvider)
    )
      .to.emit(habitatDiamond, 'ProposalCreated')
      .withArgs('moduleManager', nextMMProposal);
    // now we have to decide on the proposal (each signer has to send his "decide" tx)
    for (let i = 1; i < threshold; i++) {
      await expect(
        habitatDiamond
          .connect(impersonatedSigners[i])
          .decideOnModuleManagerProposal(nextMMProposal, true)
      )
        .to.emit(deciderSigners, 'Decided')
        .withArgs(impersonatedSigners[i].address, 'moduleManager', nextMMProposal, true);
    }
    // after everyone decided, let's accept proposal
    const moduleManagerMethods = await habitatDiamond.getModuleManagerMethods();
    const ifaceM = new ethers.utils.Interface(['function changeAddressesProvider(address)']);
    const callData = ifaceM.encodeFunctionData('changeAddressesProvider', [newAddressesProvider]);
    await expect(habitatDiamond.acceptOrRejectModuleManagerProposal(nextMMProposal))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('moduleManager', nextMMProposal, moduleManagerMethods, 0, callData);

    // let's execute proposal
    await expect(habitatDiamond.executeModuleManagerProposal(nextMMProposal))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', nextMMProposal);
    // let's prove that we have new addresses provider
    const currentAddressesProvider = await habitatDiamond.getAddressesProvider();
    expect(currentAddressesProvider).to.eq(newAddressesProvider);
  });

  it('ModuleManager/Signers: should be able to execute diamondCut proposal', async function () {
    const { habitatDiamond, deciderSigners, addressesProvider } = await helpers.loadFixture(
      deployDAOAndDistributeAndVPEnoughForGovernanceFixture
    );
    // testing our ModuleManager functionality (Decision type: Signers)
    // diamondCut method
    // this method is general from EIP2535, allows to make diamond cut, e.i.
    // add/remove/replace facets and initialize/rewrite storage values

    // testing case:
    //   let's remove daoViewerFacet using diamondCut without removing storage

    // let's simulate the gnosis offchain decision process by executing from
    // gnosis safe address
    const gnosisSafe = await deciderSigners.gnosisSafe();
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);
    const habitatDAOGnosisSigner = habitatDiamond.connect(impersonatedGnosisSafe);

    // dao viewer facet
    const daoViewerFacet = await addressesProvider.getDAOViewerFacet();

    // let's prove that dao viewer facet is part of dao at this stage
    const daoName = await habitatDiamond.getDAOName();
    expect(daoName).to.eq('HabitatDAO');

    // let's prepare params for diamondCut proposal to remove dao viewer facet
    const diamondCut = [
      {
        facetAddress: '0x0000000000000000000000000000000000000000',
        action: 2,
        functionSelectors: daoViewerFacet.functionSelectors,
      },
    ];

    const proposalId = await habitatDAOGnosisSigner.callStatic.diamondCutInitProposal(
      diamondCut,
      '0x0000000000000000000000000000000000000000',
      '0x'
    );

    // let's make a diamondCut
    await expect(
      habitatDAOGnosisSigner.diamondCutBatchedExecution(
        diamondCut,
        '0x0000000000000000000000000000000000000000',
        '0x'
      )
    )
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('moduleManager', proposalId);

    // let's prove that our dao does not have dao viewer facet anymore
    await expect(habitatDiamond.getDAOName()).to.be.revertedWith(
      'Diamond: Function does not exist'
    );
  });
});
