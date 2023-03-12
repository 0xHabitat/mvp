# HabitatDAO Contracts

This repository contains the smart contracts for the HabitatDAO, planned to be deployed on Optimism.
Contract structure is based on EIP2535.

The core of HabitatDAO is a management system contains 5 modules(Module manager, Governance, Treasury, SubDAO creation and Launchpad modules) and 2 decision systems(Voting Power ERC20 and Signers) to make onchain/offchain decisions around modules.

Contracts are still under development.

## Setup

```bash
yarn
yarn build
```

## Test
As a focused chain to deploy is Optimism, Optimism fork is used for tests, what requires to provide Alchemy token (.env).

Deployment is divided on two parts: environment contracts (facets, init contracts, deployers and etc.) and dao contract.

To optimize development process environment contracts are deployed one time (happens after running tests as well), what is fixed into scripts/deployed.json.

### Single terminal test
In order to run tests multiple times, the redeploy flag in scripts/deployed.json file must be set to true.

```bash
yarn test
```
### Two terminals test

in first terminal:

```bash
yarn start:node
```

in second terminal:

```bash
yarn test:node
```

If node is rerun, the redeploy flag in the scripts/deployed.json file must be set to true.

## Deploy HabitatDAO

File initParams.json contains a DAO initial configuration parameters.

Currently, the deployment is chain specific (Optimism) and as contracts are not production ready, the deployment is allowed only locally to optimism fork.  

in separate terminal:

```bash
yarn start:node
```

then in main terminal:

```bash
yarn deployDAO
```

## Deploy with Gemcutter

More info about Gemcutter https://0xhabitat.org/docs/Developers/Gemcutter/

### Running the local node
```bash
yarn start:node
```

### Initialize a diamond.json from a DIAMONDFILE

Currently, Gemcutter deployment is outdated.

```bash
yarn diamond:init
```
