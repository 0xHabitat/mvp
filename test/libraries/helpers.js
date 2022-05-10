/* global ethers */

//main diamond
async function diamondFacetCut() {
  //predeploy loupe facet contract
  const LouperFactory = await ethers.getContractFactory('DiamondLoupeFacet');
  const louper = await LouperFactory.deploy();
  await louper.deployed();

  //predeploy ownership facet contract
  const OwnerFactory = await ethers.getContractFactory('OwnershipFacet');
  const owner = await OwnerFactory.deploy();
  await owner.deployed();

  //predeploy diamondCut facet contract
  const CutterFactory = await ethers.getContractFactory('DiamondCutFacet');
  const cutter = await CutterFactory.deploy();
  await cutter.deployed();

  const facetCuts = [
    {
      target: cutter.address,
      action: 0,
      selectors: Object.keys(cutter.interface.functions)
      // .filter((fn) => fn != 'init()')
      .map((fn) => cutter.interface.getSighash(fn),
      ),
    },
    {
      target: louper.address,
      action: 0,
      selectors: Object.keys(louper.interface.functions)
      .map((fn) => louper.interface.getSighash(fn),
      ),
    },
    {
      target: owner.address,
      action: 0,
      selectors: Object.keys(owner.interface.functions)
      .map((fn) => owner.interface.getSighash(fn),
      ),
    },
  ];

  return facetCuts;
}

//governance upgrade global vars
async function governanceFacetCut() {
  //deploy offchain cut initializer contract
  const InitGovernance = await ethers.getContractFactory('GovernanceTokenInit');
  const initgovernance = await InitGovernance.deploy();
  await initgovernance.deployed();

  //deploy uninitialized token contract
  const TokenFactory = await ethers.getContractFactory('Token');
  const token = await TokenFactory.deploy();
  await token.deployed();

  //deploy uninitialized governance contract
  const GovernanceFactory = await ethers.getContractFactory('Governance');
  const governance = await GovernanceFactory.deploy();
  await governance.deployed();

  //declare facets to be cut
  const facetCuts = [
    {
      target: token.address,
      action: 0,
      selectors: Object.keys(token.interface.functions)
      // .filter((fn) => fn != 'init()')
      .map((fn) => token.interface.getSighash(fn),
      ),
    },
    {
      target: governance.address,
      action: 0,
      selectors: Object.keys(governance.interface.functions)
      .map((fn) => governance.interface.getSighash(fn),
      ),
    },
  ];

  return {
    facetCuts,
    initgovernance
  }
  
}

function hashData({ types, values, nonce, address }) {
  const hash = ethers.utils.solidityKeccak256(
    [...types, 'uint256', 'address'],
    [...values, nonce, address],
  );
  return ethers.utils.arrayify(hash);
}

let nonce;
let currentNonce = ethers.constants.Zero;
const nextNonce = function () {
  currentNonce = currentNonce.add(ethers.constants.One);
  return currentNonce;
};

async function multisigTX(target, data, value, delegate, contract, signers, address) {
  nonce = nextNonce();

  let signatures = [];
  for (let signer of signers) {
    let sig = await signer.signMessage(hashData({
      values: [target, data, value, delegate],
      types: ['address', 'bytes', 'uint256', 'bool'],
      nonce,
      address,
    }));
    signatures.push({ data: sig, nonce });
  }

  await contract.verifyAndExecute(
    { target, data, value, delegate },
    signatures,
    { value },
  );

  return true;
}



exports.governanceFacetCut = governanceFacetCut
exports.diamondFacetCut = diamondFacetCut
exports.hashData = hashData
exports.multisigTX = multisigTX
