// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BikeToken} from "../src/BikeToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private constant INITIAL_MINT = 4 * 25 * 1e18;

    function run() external returns (MerkleAirdrop, BikeToken) {
        return deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BikeToken) {
        vm.startBroadcast();
        BikeToken token = new BikeToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, IERC20(address(token)));
        token.mint(address(merkleAirdrop), INITIAL_MINT);
        vm.stopBroadcast();

        return (merkleAirdrop, token);
    }
}
