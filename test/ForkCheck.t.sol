// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/NEBAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract BaseSepoliaForkTest is Test {
    NEBAToken public token;
    address adminTreasury = makeAddr("admin");
    address upgrader = makeAddr("upgrader");
    address bot = makeAddr("bot");
    address user = makeAddr("user");

    function setUp() public {
        // Deploy and initialize
        NEBAToken impl = new NEBAToken();
        bytes memory data = abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, upgrader, bot);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        token = NEBAToken(address(proxy));
    }

    function test_DeploymentOnBaseSepolia() public view {
        assertEq(token.totalSupply(), 1_000_000_000 * 10 ** 18);
        assertEq(token.balanceOf(adminTreasury), token.INITIAL_SUPPLY());
    }

    function test_Transfer() public {
        vm.prank(adminTreasury);
        token.transfer(user, 1000 * 10 ** 18);
        assertEq(token.balanceOf(user), 1000 * 10 ** 18);
    }

    function test_PauseAndUnpause() public {
        vm.prank(adminTreasury);
        token.pause();
        assertTrue(token.paused());

        vm.prank(adminTreasury);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_BotCanPauseOnly() public {
        vm.prank(bot);
        token.pause();
        assertTrue(token.paused());

        vm.prank(bot);
        vm.expectRevert();
        token.unpause();
    }

    function test_Upgrade() public {
        NEBAToken newImpl = new NEBAToken();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(newImpl), "");
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }
}
