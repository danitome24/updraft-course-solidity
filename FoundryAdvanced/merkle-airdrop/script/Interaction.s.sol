// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdrop__InvalidSignatureLength();

    address constant CLAIM_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIM_AMOUNT = 25 * 1e18;

    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE = hex"6f725001fd4600fd37a653997e268a8fc6d1749b545601dd3043121e8763e7364686bccd9c214cb76c8c37a978894266fd33efae391dded4f6447723bec6c1431c";

    function claimAirdrop(address airdropContract) internal {

        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop merkleAirdrop = MerkleAirdrop(airdropContract);
        merkleAirdrop.claim(CLAIM_ADDRESS, CLAIM_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory signature) public pure returns(uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert ClaimAirdrop__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

    function run() external {
        address mostRecentlyAirdropContract = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyAirdropContract);
    }
}
