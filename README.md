# Exploring upgradeability with zeppelinOS

## Overview

This is a simple contract that can receive donations and mints a ERC721 token in exchange. It demonstrates the use of zeppelinOS to make smart contracts upgradeable.

## Upgradeability

Smart contract upgradeability can be achieved by separating the storage of a contract from its logic. The user interacts with a proxy that holds the storage and delegetecalls the logic in a referenced contract. That reference can be updated, when a new logic contract should be used. The big potential problem is that the logic contract could overwrite the storage of the proxy. There are [different ways](https://blog.zeppelinos.org/proxy-patterns/) to avoid this. ZeppelinOS uses [unstructured storage](https://github.com/zeppelinos/labs/tree/master/upgradeability_using_unstructured_storage) which allows the logic contracts to live independently of the proxy and only with [minor modifications](https://docs.zeppelinos.org/docs/writing_contracts.html) as compared to regular contracts.

## ZeppelinOS Documentation

Zeppelin has a lot of guides and tutorials and it gets a bit wild because many of them are outdated, but the current docs at https://docs.zeppelinos.org are very well organized and thorough. In addition, [this hidden page](https://docs.zeppelinos.org/docs/low_level_contract.html) gives a very good low-level understanding of the various steps that are abstracted by the zos CLI commands.

## All steps to implement upgradeability

This is new stuff, so even though most of it is well explained in the docs, I will outline all the necessary steps to create an upgradeable project using the contract in this repository as an example. The first 3 steps are pretending that we are starting with an empty slate. If you run `npm install` on this repository you can jump in straight to "Interact with contract".

### Create zos project

```
npm install --global zos
mkdir upgradeable-donations
cd upgradeable-donations
npm init
zos init upgradeable-donations
```

### Install dependencies
```
npm install --save zos-lib
npm install --save truffle 
zos link openzeppelin-eth
```
openzeppelin-eth makes Zeppelins standard libraries available through on-chain upgradeable contracts. In testing you have to deploy them yourself (once), while on the mainnet they are already deployed.

### Write your contract

Write the Donations contract. Make sure it has an initialize function instead of a constructor. You might also have to tweak the compiler version (see note below).

### Set up and connect to local blockchain
```
npm install -g ganache-cli
ganache-cli --port 9545 --deterministic
zos session --network local --from <nonAdminAddress> --expires 3600
```
The nonAdminAddress should be an address available in your ganache console, but not the first one (see notes below).

### Deploy contract

#### Add contract to your ZeppelinOS project
`
zos add Donations
`

#### Deploy the first logic contract
```
zos push --deploy-dependencies
```
This creates the first logic instance of the contract which is not yet initialized. If there was a constructor that set some state variables, a proxy that would reference this logic contract would not have a way of knowing about those state changes. That is why the constructor is replaced by the initialize function, that can be called by the proxy to make sure the proxy is in on the action from the start.

#### Deploy the first proxy contract
```
zos create Donations --init initialize --args 5,AchillsPiggybank
```
Now we have a proxy which is what the user will be interacting with. It initializes the logic contract and sets the minDonation to 5, and the contractName to AchillsPiggybank.

### Interact with contract
We can now call some functions on that proxy contract to check if it works:
```
npx truffle console --network local
Donations.deployed().then(res=>{contract=res})
contract.minDonation.call().then(res=>{console.log(res)}) // 5
contract.reduceMinDonation()
contract.minDonation.call().then(res=>{console.log(res)}) // 4
contract.increaseMinDonation() // contract.increaseMinDonation is not a function!
```

### Update contract
Let's say we forgot to include increaseMinDonation and want to add this in an upgrade to our contract. We can just modify the Donations.sol contract by adding the function in:

```
function increaseMinDonation() public {
    minDonation += 1;
}
```

Then we run:

```
Zos push 
Zos update Donations
```
And a new logic contract gets deployed that automatically points at the same proxy. We can verify this:
```
npx truffle console --network local
Donations.deployed().then(res=>{contract=res})
contract.increaseMinDonation() // works now!
contract.minDonation.call().then(res=>{num=res}) // 5
```


## Notes on deviations from the official docs

### Manually add truffle

Installing ZeppelinOS as per the docs did not automatically add truffle to my repository, so I had to add it manually using `npm install --save truffle`. I also ran into trouble with the Solidity compiler versions and ended up fixing it at 0.4.24 by adding this property to the exported object in truffle-config.js:

```
compilers: {
    solc: {
      version: "0.4.24" // otherwise compiler version problems
    }
  }
```

### ProxyAdmin cannot make function calls

It is also important to start a session with an address that is different from the default sender address in your ganache setup:

```
zos session --network local --from <nonDefaultAddress> --expires 3600

```

### Calling functions through truffle console

