// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {NEBAToken} from "../contracts/NEBAToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNEBAToken is Script {
    address public adminTreasury;
    address public upgraderAddress;
    address public botAddress;

    NEBAToken public implementation;
    NEBAToken public nebaToken;
    ERC1967Proxy public proxy;

    function setUp() public {
        adminTreasury = vm.envOr("ADMIN_TREASURY_ADDRESS", address(0));
        upgraderAddress = vm.envOr("UPGRADER_ADDRESS", address(0));
        botAddress = vm.envOr("BOT_ADDRESS", address(0));

        require(adminTreasury != address(0), "ADMIN_TREASURY_ADDRESS not set");
        require(upgraderAddress != address(0), "UPGRADER_ADDRESS not set");
        require(botAddress != address(0), "BOT_ADDRESS not set");
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Admin Treasury:", adminTreasury);
        console.log("Upgrader Address:", upgraderAddress);
        console.log("Bot Address:", botAddress);

        vm.startBroadcast(deployerPrivateKey);

        implementation = new NEBAToken();
        console.log("Implementation deployed at:", address(implementation));

        bytes memory initData =
            abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, upgraderAddress, botAddress);

        proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        nebaToken = NEBAToken(address(proxy));
        console.log("Token name:", nebaToken.name());
        console.log("Token symbol:", nebaToken.symbol());
        console.log("Total supply:", nebaToken.totalSupply());
        console.log("Admin Treasury balance:", nebaToken.balanceOf(adminTreasury));

        bytes32 DEFAULT_ADMIN_ROLE = 0x00;
        bytes32 ADMIN_PAUSER_ROLE = nebaToken.ADMIN_PAUSER_ROLE();
        bytes32 BOT_PAUSER_ROLE = nebaToken.BOT_PAUSER_ROLE();
        bytes32 UPGRADER_ROLE = nebaToken.UPGRADER_ROLE();

        console.log("\n=== Role Verification ===");
        console.log("Admin has DEFAULT_ADMIN_ROLE:", nebaToken.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury));
        console.log("Admin has ADMIN_PAUSER_ROLE:", nebaToken.hasRole(ADMIN_PAUSER_ROLE, adminTreasury));
        console.log("Bot has BOT_PAUSER_ROLE:", nebaToken.hasRole(BOT_PAUSER_ROLE, botAddress));
        console.log("Upgrader has UPGRADER_ROLE:", nebaToken.hasRole(UPGRADER_ROLE, upgraderAddress));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("Implementation:", address(implementation));
        console.log("Proxy (Token):", address(proxy));
        console.log("Use Proxy address for all interactions");
    }
}
