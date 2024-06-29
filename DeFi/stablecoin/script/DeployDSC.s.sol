// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Script} from "forge-std/Script.sol";

contract DeployDSC is Script {
    function run() external returns (DecentralizedStableCoin, DSCEngine) {
        address[] memory emptyArray = new address[](0);

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(emptyArray, emptyArray, address(dsc));
        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        return (dsc, dscEngine);
    }
}
