//spdx-license-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig
            .getConfigByChainId(block.chainid);

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, ) = createSubscription.createSubscription(
                config.vrfCoordinator,
                config.account
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit,
            config.vrfCoordinator
        );
        vm.stopBroadcast();

        // vm.startBroadcast();
        // VRFCoordinatorV2Mock(config.vrfCoordinator).addConsumer(
        //     config.subscriptionId,
        //     address(raffle)
        // );
        // vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            config.vrfCoordinator,
            config.subscriptionId,
            address(raffle),
            config.account
        );

        return (raffle, helperConfig);
    }
}
