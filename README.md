# mvp

## setup

```
yarn
yarn build
```

## test
To run tests you first need to add alchemyToken.json with your alchemyToken.
```
yarn test
```

## deploy

in separate terminal:

```
yarn run hardhat node
```

then in main terminal:

```
yarn deploy
```

## Gemcutter

Gemcutter is a simple way to work on EIP-2545 Diamonds
 
### diamond.json

The diamond.json is a temporary file that rappresents the state of the deployed diamond. The developer edits the diamond.json file and then uses gemcutter's tool to synchronize the changes to the deployed diamond. Gemcutter offers a series of functions to work with the diamond.json.

The diamond.json is not committed on github because its values depends on the local development environment. Instead the user will commit a DIAMONDFILE, a file containing all the operations used to generate the same diamond.json in every dev env.

### Gemcutter actions

```bash
npx hardhat diamond:init
```
Generates a diamond.json file starting from a DIAMONDFILE

```bash
npx hardhat diamond:deploy
```
Used to initialize a new diamond, deploying an empy diamond, and creating a diamond.json that rappresents that diamond

```bash
npx hardhat diamond:add --remote --save-metadata --address 0x3D004D6B32D5D6A5e7B7504c3dac672456ed95dB
```
Used to add a facet to the diamond.json file (not on the deployed contract).
* `--remote` to add a remote facet, `--address` is mandatory. With `--save-metadata` the metadata of the contracts are extracted from the bytecode and saved in the *./metadata/* folder.
* `--local` to add a local facet, `--name` is mandatory (the name of the facet in the *./contracts/* folder)

```bash
npx hardhat diamond:cut --init-contract MyToken --init-fn initMyToken --init-params "Habitat,HBT,8,0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
```
Used to synchronize the changes between the local diamond.json file and the deployed diaomond.
* `--init-contract` used to specify the contract from which to use the function to pass to the *_init* function in the cut.
* `--init-fn` the function to pass to the *_init* function in the cut
* `--init-params` the parameters to pass to the *_init* function in the cut

### DIAMONDFILE

The DIAMONDFILE contains the set of instructions to deploy a diamond and cut all the necessary facets. While developing the developer will call `diamond:add` and `diamond:cut` but efore committing the developer must update the DIAMONDFILE so it includes all the *adds* and *cuts* she made.

### Local node

Everything works only when the `hardhat node` is running. If the developer publishes new facets with the `--local` flag, each time it reruns the local node, it must recreate the diamond.json file redeploying the diamond on the local network.

### Network forking

Right now the basic facets (*DiamondCutFacet*, *DiamondInit*, *DiamondLoupeFacet*, *OwnershipFacet*) are deployed on rinkeby, in the future the system will use create2 to have always the same address so it will not be mandatory to fork rinkeby to work with Gemx.js.
Also in the future the `diamon:add` task will have a `--ens` parameter so the developer can add facets passing a meaningful name.

E.g.
```bash
npx hardhat diamond:add --remote --save-metadata --ens erc20.facets.eth
```

## Shortcut scripts

### Running the local node
```bash
yarn start:node
```

### Initialize a diamond.json from a DIAMONDFILE

```bash
yarn diamond:init
```