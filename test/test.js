const { expect } = require('chai');
const { deployMockContract } = require('ethereum-waffle');
const { ethers, waffle } = require('hardhat');

const {
  deploy,
  createDiamond
} = require('../scripts/deploy.js');
const { createAddFacetCut } = require('../scripts/libraries/cuts.js');

describe('Diamond', function () {

  let signers;
  let ontap;
  let git;
  let readable, ownable, erc165, writable;
  let ontapinit;

  describe('Scenarios', function () {

    before(async function () {

      signers = await ethers.getSigners();
      [ ontap, readable, ownable, erc165, writable, git, ontapinit ] = await deploy();

    });

    describe('Upgrades', function() {

      it('creates new diamond and adds facets', async function () {

        const contracts = [readable, ownable, erc165, writable];

        const cuts = createAddFacetCut(contracts);

        const diamond = await createDiamond(signers[1], cuts, ontapinit.address);

        //check that all facets are present
        const x_readable = await ethers.getContractAt('Readable', diamond.address);
        const facetAddresses = await x_readable.facetAddresses();
        const contractAddresses = contracts.map(x => x.address);
        for (let i = 0; i < facetAddresses.length; i++) {
          expect(contractAddresses[i]).to.equal(facetAddresses[i]);
        }
      });

      // it('', async function () {});
      
    });
  });
});
