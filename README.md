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

## deploy habitat DAO

in separate terminal:

```
yarn run hardhat node
```

then in main terminal:

```
yarn deployDAO
```

./scripts/deployed.json has two values, that are rewritten after deployment, if you run/rerun node again paste in "redeploy" key "true" value 

## deploy with Gemcutter

More info about Gemcutter https://0xhabitat.org/docs/Developers/Gemcutter/

### Running the local node
```bash
yarn start:node
```

### Initialize a diamond.json from a DIAMONDFILE

```bash
yarn diamond:init
```
