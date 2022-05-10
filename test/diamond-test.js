const { expect } = require('chai');
const { deployMockContract } = require('ethereum-waffle');
const { ethers, waffle } = require('hardhat');
const { 
  governanceFacetCut, 
  diamondFacetCut,
  hashData, 
  multisigTX } = require('./libraries/helpers.js');

describe('Diamond', function () {
  let user1, user2, user3, user4, user5;
  let diamond, proxy;
  let cutterfacet, louperfacet, ownerfacet;
  let repofacet, tokenfacet, governancefacet;

  describe('Scenarios', function () {

    before(async function () {
      [user1, user2, user3, user4, user5] = await ethers.getSigners();
      const facetCuts = await diamondFacetCut(); //test helper

      //deploy diamond contract
      const DiamondFactory = await ethers.getContractFactory('Diamond');
      diamond = await DiamondFactory.connect(user1).deploy(facetCuts); //owned by user1
      await diamond.deployed()

      cutterfacet = await ethers.getContractAt('DiamondCutFacet', diamond.address)
      louperfacet = await ethers.getContractAt('DiamondLoupeFacet', diamond.address)
      ownerfacet = await ethers.getContractAt('OwnershipFacet', diamond.address)
    });

    describe('Single User', function() {

      it('user clones with new diamond', async function () {
        // get facets
        const facets = await louperfacet.facets();

        // convert to facetCuts[] objects
        let facetCuts = [];
        let target;
        let selectors;
        let action = 0;
        for (let i = 0; i < facets.length; i++) {
          target = facets[i].target;
          selectors = facets[i].selectors;
          facetCuts.push({
            target,
            action,
            selectors
          })
        }

        //deploy new diamond contract with cuts in constructor
        const NewDiamondFactory = await ethers.getContractFactory('Diamond');
        const newDiamond = await NewDiamondFactory.connect(user4).deploy(facetCuts);
        await newDiamond.deployed();

        // functions of diamond are accessible via newdiamond, but newdiamond holds its own state
        const newDiamond_Owner = await ethers.getContractAt('OwnershipFacet', newDiamond.address)
        expect(await newDiamond_Owner.owner()).to.equal(user4.address)
      });

      it('user clones with diamond-proxy', async function() {
        //deploy normal proxy that mirrors diamond
        const ProxyFactory = await ethers.getContractFactory('DiamondProxy')
        proxy = await ProxyFactory.connect(user5).deploy(diamond.address);
        await proxy.deployed()

        // functions of diamond are accessible via proxy, but proxy holds its own state
        const proxy_ownerfacet = await ethers.getContractAt('OwnershipFacet', proxy.address)
        expect(await proxy_ownerfacet.owner()).to.equal(user5.address)
      });

      it('diamond-forwarder makes calls to any diamond', async function() {
        const DiamondForwarderFactory = await ethers.getContractFactory('DiamondForwarder')
        const diamondforwarder = await DiamondForwarderFactory.connect(user2).deploy(diamond.address);
        await diamondforwarder.deployed()

        const forwader_ownerfacet = await ethers.getContractAt('OwnershipFacet', diamondforwarder.address)
        let calldata = forwader_ownerfacet.interface.encodeFunctionData("transferOwnership", [user3.address])
        await expect(
          diamondforwarder.connect(user1).callStatic.forward(diamond.address, calldata)
        ).to.be.revertedWith('Ownable: sender must be owner')
      });
      
    });

    describe('Upgrades', function() {
      let multisig, signers, quorum;
      let upgradeRegistry;
      let facetCuts, initgovernance;

      // event parsing vars
      let tx, delivered, event;

      //governance proposal vars
      let proposalContract, currentBlock, deadline;

      //upgrade registry event returned vars
      let ownerAddr, minimalProxyAddr, facetCutArray, initializerAddr, initializerFunc;

      //multisig tx args
      let target, data, value, delegate, contract, address;

      before(async function () {

        //deploy upgrade contract
        const UpgradeRegistryFactory = await ethers.getContractFactory('UpgradeRegistry')
        upgradeRegistry = await UpgradeRegistryFactory.deploy();
        await upgradeRegistry.deployed()
        // set secure parent placeholder
        const GreeterFactory = await ethers.getContractFactory('Greeter')
        const greeter = await GreeterFactory.deploy();
        await greeter.deployed()
        facetCuts = [
          {
            target: greeter.address,
            action: 0,
            selectors: Object.keys(greeter.interface.functions)
            .map((fn) => greeter.interface.getSighash(fn),
            ),
          },
        ];
        await upgradeRegistry.set(diamond.address, facetCuts, ethers.constants.AddressZero, '0x');

        //set vars of factory-model multisig
        signers = [user1, user2, user3];
        quorum = 2;

        //predeploy repo contract
        const Repository = await ethers.getContractFactory('Repository');
        const repository = await Repository.deploy(signers.map(s=>s.address), quorum);
        await repository.deployed();
        ({ facetCuts, initgovernance } = await governanceFacetCut()); //test helper
        facetCuts.push(
          {
            target: repository.address,
            action: 0,
            selectors: Object.keys(repository.interface.functions)
            .map((fn) => repository.interface.getSighash(fn),
            ),
          },
        );

        await cutterfacet.diamondCut(facetCuts, initgovernance.address, '0xe1c7392a');

        repofacet = await ethers.getContractAt('Repository', diamond.address)
        tokenfacet = await ethers.getContractAt('Token', diamond.address)
        governancefacet = await ethers.getContractAt('Governance', diamond.address)
      });

      it('deploys team', async function () {
        signers = [user3, user4, user5];
        quorum = 2;
        tx = await repofacet.deployTeam(signers.map(s=>s.address), 2);
        delivered = await tx.wait(); // 0ms, as tx is already confirmed
        event = delivered.events.find(event => event.event === 'TeamDeployed');
        const [teamAddr] = event.args;
        const deployedTeam = await ethers.getContractAt('MultisigWallet', teamAddr)
        multisig = deployedTeam.address;
      });

      it('team recieves upgrade-credits from dao vote', async function () {
        //call execute() via governance, grants team-Multisig 1 upgrade credit
        proposalContract = multisig;
        currentBlock = await ethers.provider.getBlockNumber();
        deadline = (await ethers.provider.getBlock(currentBlock)).timestamp + 10;

        await governancefacet.connect(user1).propose(proposalContract, deadline);

        await governancefacet.connect(user2).vote(0, true)

        await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
        await network.provider.send("evm_mine");

        await governancefacet.executeProposal(0);
        expect(await governancefacet.proposalStatus(0)).to.equal(5);
      });

      it('some dude registers upgrade', async function () {
        const TestFacet1Factory = await ethers.getContractFactory('TestFacet1')
        testfacet1 = await TestFacet1Factory.deploy()
        await testfacet1.deployed()

        const TestFacet2Factory = await ethers.getContractFactory('TestFacet2')
        testfacet2 = await TestFacet2Factory.deploy()
        await testfacet2.deployed()

        const TestInit = await ethers.getContractFactory('TestInit')
        testinit = await TestInit.deploy()
        await testinit.deployed()
        facetCuts = [
          {
            target: testfacet1.address,
            action: 0,
            selectors: Object.keys(testfacet1.interface.functions)
            .map((fn) => testfacet1.interface.getSighash(fn),
            ),
          },
          {
            target: testfacet2.address,
            action: 0,
            selectors: Object.keys(testfacet2.interface.functions)
            .map((fn) => testfacet2.interface.getSighash(fn),
            ),
          },
        ];   
        tx = await upgradeRegistry.register(facetCuts, testinit.address, '0xe1c7392a');
        delivered = await tx.wait(); // 0ms, as tx is already confirmed
        event = delivered.events.find(event => event.event === 'UpgradeRegistered');
        ([ownerAddr, minimalProxyAddr, facetCutArray, initializerAddr, initializerFunc] = event.args)
      });

      it('team-multisig uses upgrade-credit to add upgrade to repo', async function () {
        target = diamond.address;
        ({ data } = await repofacet.populateTransaction.addUpgrade(minimalProxyAddr)  );
        value = ethers.constants.Zero;
        delegate = false;
        contract = await ethers.getContractAt('MultisigWallet', multisig);
        address = multisig;
        await multisigTX(target, data, value, delegate, contract, signers, address);
      });

      it('some dude proposes vote to add upgrade in repo', async function () {
        proposalContract = minimalProxyAddr;
        currentBlock = await ethers.provider.getBlockNumber();
        deadline = (await ethers.provider.getBlock(currentBlock)).timestamp + 10;

        await governancefacet.connect(user1).propose(proposalContract, deadline);
        await governancefacet.connect(user2).vote(1, true);

        await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
        await network.provider.send("evm_mine");

        await governancefacet.executeProposal(1);
        expect(await governancefacet.proposalStatus(1)).to.equal(5);

        const test1facet = await ethers.getContractAt('TestFacet1', diamond.address);
        expect(await test1facet.getInitializedValue()).to.equal(true);
      });

      // it('', async function () {});
      
    });
  });
});
