// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/ERC6551Registry.sol";

contract DeployRegistry is Script {
    function run() external {
        // set up deployer
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        // log deployer data
        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        vm.startBroadcast(deployer);

        ERC6551Registry registry = new ERC6551Registry();

        console2.log("Registry deployed: ", address(registry));

        vm.stopBroadcast();
    }
}
