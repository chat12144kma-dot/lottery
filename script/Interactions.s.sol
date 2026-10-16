//spdx-license-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        uint64 subID = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        return (subID, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint64, address) {
        console.log("Creating subscription on ChainID:", block.chainid);
        console.log("Using account: ", account);
        vm.startBroadcast(account);
        uint64 subID = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with ID:", subID);
        console.log(
            "Please update the subscriptionId in HelperConfig.s.sol with this new ID"
        );
        return (subID, vrfCoordinator);
    }
}

contract FundSubscription is Script, CodeConstants {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint64 subID = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        address link = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subID, link, account);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subID,
        address link,
        address account
    ) public {
        console.log("Funding subscription: ", subID);
        console.log("Funding subscription on ChainID:", block.chainid);
        console.log("Using VRFCoordinator:", vrfCoordinator);
        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subID,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subID)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentConsumer) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint64 subID = helperConfig.getConfig().subscriptionId;
        addConsumer(
            vrfCoordinator,
            subID,
            mostRecentConsumer,
            helperConfig.getConfig().account
        );
    }

    function addConsumer(
        address vrfCoordinator,
        uint64 subID,
        address consumer,
        address account
    ) public {
        console.log("Adding consumer to VRFCoordinator: ", consumer);
        console.log("Adding consumer to subscription: ", subID);
        console.log("Using VRFCoordinator: ", vrfCoordinator);
        console.log("Using account: ", account);
        vm.startBroadcast(account);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subID, consumer);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
