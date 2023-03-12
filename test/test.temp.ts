import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import * as helpers from '@nomicfoundation/hardhat-network-helpers';
import { deployDAO } from '../scripts/deployDAO';
import { getWETH } from './helpers/getContractsForUniV3';
const habitatABI = require('../habitatDiamondABI.json');

describe('DeciderSigner', function () {
  it('Signers/Treasury module: Cover treasury proposal process with decision type signers', async function () {
    this.timeout(0);
    const accounts = await ethers.getSigners();
    const signer = accounts[0];
    const beneficiarAddress = accounts[8].address;
    // first let's make treasury decision type signers
    const [daoAddress, initialDistributorAddress] = await deployDAO([3, 2, 3, 2, 3]);
    const habitatDiamond = new ethers.Contract(daoAddress, habitatABI, signer);
    // first lets have DeciderSigners instance
    const deciderSignersAddress = await habitatDiamond.getModuleDecider('treasury');
    const deciderSigners = await ethers.getContractAt('DeciderSigners', deciderSignersAddress);
    const gnosisSafe = await deciderSigners.gnosisSafe();

    // let's fund DAO treasury with some ETH and WETH
    const ten = ethers.constants.WeiPerEther.mul(10);
    const sponsor = accounts[0];
    const weth = getWETH(sponsor);
    let tx = await weth.deposit({ value: ten });
    await tx.wait();
    tx = await weth.transfer(habitatDiamond.address, ten);
    await tx.wait();
    const ethTranfer = {
      to: habitatDiamond.address,
      value: ethers.utils.parseEther('10'),
    };
    tx = await sponsor.sendTransaction(ethTranfer);
    await tx.wait();

    // Here we go two ways:
    // first: decide inside gnosis safe (offchain way) and just execute decision
    //        through gnosisSafe tx that is calling dao
    // second: decide by each signer calling dao (onchain way) and execute decision
    //         by calling dao when decision is accepted

    // first Offchain way:
    await helpers.impersonateAccount(gnosisSafe);
    const impersonatedGnosisSafe = await ethers.getSigner(gnosisSafe);

    // lets use wrapper treasury function to send weth to beneficiar
    const daoCallData = habitatDiamond.interface.encodeFunctionData(
      'sendERC20FromTreasuryBatchedExecution',
      [weth.address, beneficiarAddress, ten]
    );
    const gnosisTx = {
      to: habitatDiamond.address,
      data: daoCallData,
    };

    const daoBalanceBefore = await weth.balanceOf(habitatDiamond.address);
    const beneficiarBalanceBefore = await weth.balanceOf(beneficiarAddress);

    tx = await impersonatedGnosisSafe.sendTransaction(gnosisTx);
    await tx.wait();

    const daoBalanceAfter = await weth.balanceOf(habitatDiamond.address);
    const beneficiarBalanceAfter = await weth.balanceOf(beneficiarAddress);

    expect(daoBalanceBefore.sub(ten)).eq(daoBalanceAfter);
    expect(beneficiarBalanceBefore.add(ten)).eq(beneficiarBalanceAfter);

    // second Onchain way:

    // first impersonate signers accounts
    const iface = new ethers.utils.Interface(['function getOwners() view returns(address[])']);
    const gnosisInstance = new ethers.Contract(gnosisSafe, iface, signer);
    const signers = await gnosisInstance.getOwners();

    const impersonatedSigners = [];
    for (let i = 0; i < signers.length; i++) {
      await helpers.impersonateAccount(signers[i]);
      const signer = await ethers.getSigner(signers[i]);
      impersonatedSigners.push(signer);
    }

    // second lets create treasury proposal from one of the gnosis signers
    const proposalID = (await habitatDiamond.getModuleProposalsCount('treasury')).add(1);
    tx = await habitatDiamond
      .connect(impersonatedSigners[0])
      .createTreasuryProposal(beneficiarAddress, ten, '0x');
    await tx.wait();
    // make sure that treasury decisionType is Signers
    const decisionType = await habitatDiamond.getModuleDecisionType('treasury');
    expect(decisionType).to.eq(3);
    // lets find our proposalId in active voting
    let activeVotingProposalIds = await habitatDiamond.getModuleActiveProposalsIds('treasury');
    expect(activeVotingProposalIds.some((id: any) => id.eq(proposalID))).to.be.true;

    const proposalKey = await deciderSigners.computeProposalKey('treasury', proposalID);
    // the initiator already decided
    expect(await deciderSigners.isSignerDecided(proposalKey, impersonatedSigners[0].address)).to.be
      .true;

    // make sure decision process started
    expect(await deciderSigners.isDecisionProcessStarted(proposalKey)).to.be.true;

    // lets decide
    // lets decide not a signer
    await expect(habitatDiamond.decideOnTreasuryProposal('0x12', true)).to.be.revertedWith(
      'Only gnosis signers can decide.'
    );
    // lets decide on non-exist proposal
    await expect(
      habitatDiamond.connect(impersonatedSigners[0]).decideOnTreasuryProposal('0x12', true)
    ).to.be.revertedWith('Decision process is not started yet.');
    // lets decide second time
    await expect(
      habitatDiamond.connect(impersonatedSigners[0]).decideOnTreasuryProposal(proposalID, true)
    ).to.be.revertedWith('Already decided.');

    await expect(
      habitatDiamond.connect(impersonatedSigners[1]).decideOnTreasuryProposal(proposalID, true)
    )
      .to.emit(deciderSigners, 'Decided')
      .withArgs(impersonatedSigners[1].address, 'treasury', proposalID, true);

    await expect(
      habitatDiamond.connect(impersonatedSigners[2]).decideOnTreasuryProposal(proposalID, false)
    )
      .to.emit(deciderSigners, 'Decided')
      .withArgs(impersonatedSigners[2].address, 'treasury', proposalID, false);

    // lets try to accept not waiting voting period
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID)).to.be.revertedWith(
      'Threshold is not reached yet.'
    );

    await expect(
      habitatDiamond.connect(impersonatedSigners[3]).decideOnTreasuryProposal(proposalID, true)
    )
      .to.emit(deciderSigners, 'Decided')
      .withArgs(impersonatedSigners[3].address, 'treasury', proposalID, true);

    // accept proposal
    await expect(habitatDiamond.acceptOrRejectTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalAccepted')
      .withArgs('treasury', proposalID, beneficiarAddress, ten, '0x');

    // confirm proposalId is removed from active
    activeVotingProposalIds = await habitatDiamond.getModuleActiveProposalsIds('treasury');
    expect(activeVotingProposalIds.some((id: any) => id.eq(proposalID))).to.be.false;

    // execute proposal
    const beneficiarETHBalanceBefore = await ethers.provider.getBalance(beneficiarAddress);
    const habitatDAOETHBalanceBefore = await ethers.provider.getBalance(habitatDiamond.address);
    // let execute
    await expect(habitatDiamond.executeTreasuryProposal(proposalID))
      .to.emit(habitatDiamond, 'ProposalExecutedSuccessfully')
      .withArgs('treasury', proposalID);

    // confirm receiving eth
    const beneficiarETHBalanceAfter = await ethers.provider.getBalance(beneficiarAddress);
    expect(beneficiarETHBalanceBefore.add(ten)).to.eq(beneficiarETHBalanceAfter);
    const habitatDAOETHBalanceAfter = await ethers.provider.getBalance(habitatDiamond.address);
    expect(habitatDAOETHBalanceBefore.sub(ten)).to.eq(habitatDAOETHBalanceAfter);
  });
});
