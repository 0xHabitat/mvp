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
