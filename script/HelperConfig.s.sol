// spdx-license-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

error helperConfig__NoNetworkConfigFound();

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    struct NetworkConfig {
        address vrfCoordinator;
        uint256 entranceFee;
        uint256 interval;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public localConfig;

    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ANVIL_CHAIN_ID] = getOrCreateAnvilEthConfig();
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            return getSepoliaEthConfig();
        } else if (chainId == ANVIL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert helperConfig__NoNetworkConfigFound();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                entranceFee: 0.01 ether,
                interval: 30,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: 0xD31788d01655f9225Ee3Be322675C0c61B1496B4
            });
    }
    //deploy a mock vrf coordinator and create a subscription

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localConfig.vrfCoordinator != address(0)) {
            return localConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether,
            1e9
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinator),
            entranceFee: 0.01 ether,
            interval: 30,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(link),
            account: 0x4e59b44847b379578588920cA78FbF26c0B4956C
        });

        return localConfig;
    }
}
