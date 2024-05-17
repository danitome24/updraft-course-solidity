#### Deploy

forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xAAAAAAAAA

forge script script/DeploySimpleStorage.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY

#### from hex to basse
cast --to-base 0xAAA

#### How to not use .env file

1. Copy wallet private key.
2. Use cast to import your private key with this command:

```
$ cast wallet import defaultKey --interactive
```
3. Paste your private key into terminal.
4. Type a password (12341234)