// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BikeToken} from "../src/BikeToken.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    bytes32 constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32[] public PROOF;
    uint256 constant AMOUNT_CLAIM = 25 * 1e18;
    uint256 constant AMOUNT_MINT = 100 * 1e18;

    BikeToken public token;
    MerkleAirdrop public merkleAirdrop;
    DeployMerkleAirdrop public deployer;

    address user;
    uint256 userPrivKey;
    address gasPayer;

    function setUp() external {
        PROOF.push(0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a);
        PROOF.push(0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576);

        if (!isZkSyncChain()) {
            deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, token) = deployer.run();
        } else {
            token = new BikeToken();
            merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, token);
            token.mint(token.owner(), AMOUNT_MINT);
            token.transfer(address(merkleAirdrop), AMOUNT_MINT);
        }
        (user, userPrivKey) = makeAddrAndKey("user"); // it's also the first addr than input.json
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        uint256 startingUserBalance = token.balanceOf(user);
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_CLAIM);

        // Sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_CLAIM, PROOF, v, r, s);

        uint256 endUserBalance = token.balanceOf(user);
        assertEq(startingUserBalance + AMOUNT_CLAIM, endUserBalance);
    }

    function testUserCannotClaimMoreThanOnce() public {
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.startPrank(user);
        merkleAirdrop.claim(user, AMOUNT_CLAIM, PROOF, v, r, s);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        merkleAirdrop.claim(user, AMOUNT_CLAIM, PROOF, v, r, s);
        vm.stopPrank();
    }
}
