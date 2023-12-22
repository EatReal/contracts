// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/ERC6551Registry.sol";
import "../src/ERC6551Account.sol";
import "../src/Nomad3Drops.sol";
import "../src/Nomad3.sol";

contract DeployRegistry is Script {
    function run() external {
        // set up deployer
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);

        //set up test account
        uint256 privKey2 = vm.envUint("PRIVATE_KEY_2");
        address testAccount = vm.rememberKey(privKey2);

        // log deployer data
        console2.log("Deployer: ", deployer);
        console2.log("Deployer Nonce: ", vm.getNonce(deployer));

        //specify constructor arguments
        string memory dropName = "Nomad3 Drops";
        string memory dropSymbol = "N3D";

        vm.startBroadcast(deployer);

        //first deploy the ERC6551Registry
        ERC6551Registry registry = new ERC6551Registry();

        //then, deploy the ERC6551Account
        ERC6551Account account = new ERC6551Account();

        //then, deploy the Nomad3Drops contract
        Nomad3Drops drops = new Nomad3Drops(
            dropName,
            dropSymbol,
            address(registry),
            address(account)
        );

        //then, deploy the Nomad3 contract
        Nomad3 nomad3 = new Nomad3(address(drops));

        //then, we will proceed to create an event in the Nomad3Drops contract
        //for now, metadata is just a string, but eventually it will be a hash
        //use the deployer account to create the event
        drops.registerEvent("Nomad3 Launch", 100);

        vm.stopBroadcast();

        //then, we will mint an NFT for the event. switch to the test account
        vm.startBroadcast(testAccount);
        address payable tbaAddress = drops.mintNFT(1);

        //then, create a new year album
        nomad3.createYear(2021);

        //finally, make a request to the TBA to update the event listings.
        //this is by "connecting" to the TBA using the TBA address
        ERC6551Account tba = ERC6551Account(tbaAddress);
        tba.callCreateEventOnNomad3(
            address(nomad3),
            2021,
            "Nomad3 Launch",
            1630454400,
            1
        );

        vm.stopBroadcast();

        //log the addresses of the deployed contracts
        console2.log("ERC6551Registry deployed: ", address(registry));
        console2.log("ERC6551Account deployed: ", address(account));
        console2.log("Nomad3Drops deployed: ", address(drops));
        console2.log("Nomad3 deployed: ", address(nomad3));
        console2.log("TBA deployed: ", tbaAddress);
    }
}
