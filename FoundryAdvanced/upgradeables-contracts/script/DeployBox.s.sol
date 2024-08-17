// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BestProxy} from "../src/BestProxy.sol";

contract DeployBox is Script {
    function deployBox() public returns (address) {
        vm.startBroadcast();

        BoxV1 boxV1 = new BoxV1(); // <- Implementation (Logic)

        BestProxy proxy = new BestProxy(address(boxV1), ""); // <- Proxy

        vm.stopBroadcast();

        return address(proxy);
    }

    function run() external returns (address) {
        address proxy = deployBox();

        return proxy;
    }
}
