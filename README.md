# DEPRToken & Sale contracts
This repositories contains the token and its pre sale contract. 

`fundsReceiver` will receive ETH invested by the investors.

Note - `initialMint()` should be the first transaction performed by the owner of the ERC20 token by passing `saleContractAddress` to mint the tokens to the sale contract and for owner of the contract for the desired allocation. This function can only be called once by the owner of the contract.

## Prerequisite
- Truffle ^5.0.0.  
- NPM ^6.4.1
- Node ^10.13.0

## Compile
```
truffle compile
```

## Migrate
```
truffle migrate
```

# Ropsten contracts   


# Mainnet contracts
