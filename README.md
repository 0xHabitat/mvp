# OnTap Git Control System ... A Diamond for Storing Upgrade Presets

>This is a simple WIP / concept project and there are no immediate plans other than testing, simplifying, and optimizing the contracts further. OnTap is the diamond name we will use for this example. This readme is more digestible if you have some familiarity with EIP2535 and the [Solidstate contract library](https://github.com/solidstate-network/solidstate-solidity).

## The Upgrade contract - storing upgrades
This is an evolution of the 0xhabitat/mvp governance_experiments branch active June 8, 2022. It uses the same approach of upgrading the diamond by calling an external contract (a minimal proxy of the original Upgrade.sol) that is storing data in the format of a standard diamondCut `( ( address[], uint8, bytes4[] ), initializerAddress, initializerFunction )`. 

<img width="675" alt="Screen Shot 2022-06-08 at 12 36 18 AM" src="https://user-images.githubusercontent.com/62122206/172532551-67dda429-36da-49ea-a4ab-ce6522150bb7.png">


## Storage - A basic data structure
Moving on from the external [Upgrade.sol](./contracts/external/Upgrade.sol) storage contract; the main [Storage library contract](./contracts/storage/Storage.sol) contains a [solidstate](https://github.com/solidstate-network/solidstate-solidity) compatible storage layout with some internal functions for easy access. 

<img width="629" alt="Screen Shot 2022-06-08 at 12 37 52 AM" src="https://user-images.githubusercontent.com/62122206/172532754-4a8a5b1b-c5f4-4dfb-897d-6f9bb8d1ff39.png">


## The logic
The [logic folder](./contracts/logic/) contains the two main facets and a library for sharing code between modules...

### Git contract
[Git / IGit](./contracts/logic/Git) is the native facet of OnTap. It is the main access point for reading and writing upgrades and presets to this Diamond's storage. 

**Looking at the code:** You can see that upon deployment, an address for the Upgrade.sol model is stored immutably. This address can then be used for cheaply deploying minimal proxies (storage contracts delegating calls to a single logic implementation), as seen in `function commit(...)`. 

<img width="670" alt="Screen Shot 2022-06-08 at 12 47 28 AM" src="https://user-images.githubusercontent.com/62122206/172533865-1127cd98-9034-4354-ac03-9a7143a265d0.png">


### Writable contract
[Writable / IWritable](./contracts/logic/IWritable) is an extended DiamondCutFacet which integrates itself with Git. It is to be used by other diamonds. 

**Looking at the code:** Upon deployment, it stores the Diamond immutably so that our Diamond's git system can be accessed from other diamonds if they've connected this contract as a facet. It has 2 externally available methods for upgrading a diamond...
1. `function cutAndCommit(..)`: a standard diamondCut that also commits to the caller's repo at 'name' in the OnTap diamond.
2. `function update(..)`: upgrades to the latest commit at the account arg's 'name'

<img width="684" alt="Screen Shot 2022-06-09 at 3 10 01 PM" src="https://user-images.githubusercontent.com/62122206/172925487-5a152741-6df6-4073-aea7-e45d196548fa.png">


### Internal Library contract
The [Library contract](./contracts/logic/libraries/Library.sol) contains the internal functions that all upgrades can use. These internal functions can be shared among decentralized decision-making modules. For example: when [Governance.sol](./contracts/_library/ontap/governance/logic/Governance.sol) calls `executeProposal(..)`, it calls the `Library._execute(..)` internal function, sending through its 'proposalContract' (a minimal proxy of Upgrade.sol) to make the upgrade. Additionally, since a `diamondCut(..)` function can perform arbitary operations via its 2nd and 3rd params `initializerAddress, initializerFunction`, this method can also do things like mint new tokens, or add/remove/update any data in *your* diamond. 

<img width="685" alt="Screen Shot 2022-06-08 at 2 42 29 PM" src="https://user-images.githubusercontent.com/62122206/172692673-ec764871-5ad1-48b3-8d29-6f0aa2b9574f.png">


## The OnTap Diamond
In the [main diamond](./contracts/OnTap.sol), most of the work is done in the constructor. The workflow of adding each facet can be found in the [deploy script](./scripts/deploy.js). The important bit is; Writable.sol is deployed in the constructor, because it has to store the diamond's address(this) via its *own* constructor. 

<img width="666" alt="Screen Shot 2022-06-08 at 3 05 06 PM" src="https://user-images.githubusercontent.com/62122206/172696482-aaa1f519-ab70-4db3-a187-5517a34b95f3.png">

## The User's Diamond
The [user's diamond](./contracts/_library/ontap/diamond/Diamond.sol) is a lightweight, simplified solidstate diamond that accepts cuts in its constructor, so that it can use existing facets on deployment.

<img width="672" alt="Screen Shot 2022-06-08 at 1 33 28 AM" src="https://user-images.githubusercontent.com/62122206/172539388-46d6e6bd-9125-42df-b29c-2601b5c7ed9c.png">


These contracts have not been thoroughly tested yet, but when they do, the contracts may change slightly. 

#### Extra notes: 
- The [_library folder](./contracts/_library) can be largely ignored, with the exception of its [governance folder](./contracts/_library/ontap/governance). It just contains any modules that can work with the OnTap diamond.
- The [init folder](./contracts/init) contains the upgrade initializers. These contracts can perform arbitrary operations on the diamond via the `diamondCut(..)` 2nd and 3rd params `initializerAddress, initializerFunction`.

---
# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
