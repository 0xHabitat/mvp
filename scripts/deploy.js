/* global ethers */

const { 
  createAddFacetCut,
  replaceFacet
} = require('./libraries/cuts.js');

const init = '0xe1c7392a';

// reusable facets - attached facets are prefixed with 'x_';

async function createDiamond(signer, cuts, initAddr) {

  const Diamond = await ethers.getContractFactory('Diamond');
  const diamond = await Diamond.connect(signer).deploy(cuts, initAddr, init);
  await diamond.deployed();
  console.log('💎 Diamond deployed:', diamond.address);

  return diamond;
}

async function createOntap(cuts) {

  const OnTap = await ethers.getContractFactory('OnTap');
  const ontap = await OnTap.deploy(cuts, ethers.constants.AddressZero, '0x');
  await ontap.deployed();
  console.log('💎 OnTap deployed:', ontap.address);

  return ontap;
}

async function deploy() {

  console.log('~~~~~  C R E A T I N G   O N T A P  ~~~~~')

  const Readable = await ethers.getContractFactory('Readable');
  const readable = await Readable.deploy();
  await readable.deployed();
  console.log('🔮 Readable deployed:', readable.address);

  const Ownable = await ethers.getContractFactory('Ownership');
  const ownable = await Ownable.deploy();
  await ownable.deployed();
  console.log('💍 Ownable deployed:', ownable.address);

  const ERC165 = await ethers.getContractFactory('Erc165');
  const erc165 = await ERC165.deploy();
  await erc165.deployed();
  console.log('🗺  ERC165 deployed:', erc165.address);

  let cuts = createAddFacetCut([readable, ownable, erc165]);

  const ontap = await createOntap(cuts);

  const x_writable = await ethers.getContractAt('Writable', ontap.address);
  const x_ownable = await ethers.getContractAt('Ownership', ontap.address);
  const x_readable = await ethers.getContractAt('Readable', ontap.address);

  const facetAddresses = [ontap.address, readable.address, ownable.address, erc165.address];
  const writableAddr = (await x_readable.facetAddresses()).filter((x) => {
    if (facetAddresses.indexOf(x) === -1) return x;
  })[0];
  const writable = await ethers.getContractAt('Writable', writableAddr);
  console.log('🪩  Writable deployed:', writableAddr);

  //deploy greeter
  const Greeter = await ethers.getContractFactory('Greeter');
  const greeter = await Greeter.deploy();
  await greeter.deployed();
  console.log('👋 Greeter deployed:', greeter.address);

  //deploy git
  cuts = createAddFacetCut([greeter]);
  const Git = await ethers.getContractFactory('Git');
  const git = await Git.deploy(cuts);
  await git.deployed();
  console.log('🪬  Git deployed:', git.address);

  cuts = createAddFacetCut([git]);

  //deploy initializer
  const OnTapInit = await ethers.getContractFactory('OnTapInit');
  const ontapinit = await OnTapInit.deploy();
  await ontapinit.deployed();
  console.log('💠 OnTapInit deployed:', ontapinit.address);

  await x_writable.diamondCut(cuts, ontapinit.address, init);

  console.log('~~~~~~  O N T A P   C R E A T E D  ~~~~~~');

  return [ ontap, readable, ownable, erc165, writable, git, ontapinit ];
}

if (require.main === module) {
  deploy()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deploy = deploy
exports.createDiamond = createDiamond