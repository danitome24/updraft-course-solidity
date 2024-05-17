-include .env

.PHONY: deploy 

deploy:
	forge script script/DeploySimpleStorage.s.sol --rpc-url $(RPC_URL) --broadcast --account defaultKey --sender $(ACC_ADDRESS)
