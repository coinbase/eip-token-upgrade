# EIP-4931 - Generic Token Upgrade Standard Reference Implementation

Reference Implementation for [EIP-4931](https://github.com/ethereum/EIPs/pull/4931)

## Summary
Token contract upgrades typically require each asset holder to exchange their old tokens for new ones using a bespoke interface provided by the developers.
EIP-4931 allows for the implementation of a standard API for ERC20 token upgrades. This standard specifies an interface that supports the conversion
of tokens from one contract (called the "source token") to those from another (called the "destination token"), as well as several helper methods to provide basic
information about the token upgrade. There is also an extension optionally available to provide downgrade functionality. Upgrade contract standardization will allow
centralized and decentralized exchanges to conduct token upgrades more efficiently while reducing security risks and enabling a frictionless user experience for
anyone holding an ERC20 asset during an upgrade.

This repository serves as the main reference implementation for EIP-4931 while it is under review.

## Installing Dependencies
```
npm install
```

## Compilng the Example
```
npx hardhat compile
```

## Running Tests
```
npx hardhat test
```
