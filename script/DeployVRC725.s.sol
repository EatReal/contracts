// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/VRC725Helper.sol";

contract DeployRegistry is Script {
    function run() external {
        // set up deployer
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        // log deployer data
        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        //specify constructor arguments
        string memory name = "Nomad3";
        string memory symbol = "N3";
        uint8 decimals = 18;

        vm.startBroadcast(deployer);

        //first deploy the ERC6551Registry
        VRC725Helper helper = new VRC725Helper(name, symbol, decimals);

        vm.stopBroadcast();

        //log the addresses of the deployed contracts
        console2.log("Helper: ", address(helper));
    }
}
