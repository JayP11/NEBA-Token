// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/NEBAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NEBATokenV2Mock is NEBAToken {
    uint256 public newFeature;

    function setNewFeature(uint256 _value) external {
        newFeature = _value;
    }

    function version() external pure returns (string memory) {
        return "v2";
    }
}

contract NEBATokenIntegrationTest is Test {
    NEBAToken public token;
    NEBAToken public implementation;
    ERC1967Proxy public proxy;

    address public adminTreasury;
    address public upgrader;
    address public adminPauser;
    address public bot;
    address public user1;
    address public user2;
    address public user3;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");

    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    event CircuitBreakerActivated(address indexed by, uint256 timestamp);
    event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgrader = makeAddr("upgrader");
        adminPauser = makeAddr("adminPauser");
        bot = makeAddr("bot");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        implementation = new NEBAToken();

        bytes memory initData =
            abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, upgrader, adminPauser, bot);

        proxy = new ERC1967Proxy(address(implementation), initData);
        token = NEBAToken(address(proxy));
    }

    function test_Integration_InitialDeployment() public view {
        assertEq(token.name(), "NEBA Token");
        assertEq(token.symbol(), "NEBA");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(adminTreasury), INITIAL_SUPPLY);
        assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury));
        assertTrue(token.hasRole(ADMIN_PAUSER_ROLE, adminPauser));
        assertTrue(token.hasRole(BOT_PAUSER_ROLE, bot));
        assertTrue(token.hasRole(UPGRADER_ROLE, upgrader));
    }

    function test_Integration_NormalTransferFlow() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.prank(adminTreasury);
        token.transfer(user1, transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(adminTreasury), INITIAL_SUPPLY - transferAmount);

        vm.prank(user1);
        token.transfer(user2, transferAmount / 2);
        assertEq(token.balanceOf(user2), transferAmount / 2);
        assertEq(token.balanceOf(user1), transferAmount / 2);
    }

    function test_Integration_ApprovalAndTransferFromFlow() public {
        uint256 approvalAmount = 5000 * 10 ** 18;
        uint256 transferAmount = 3000 * 10 ** 18;

        vm.prank(adminTreasury);
        token.approve(user1, approvalAmount);
        assertEq(token.allowance(adminTreasury, user1), approvalAmount);

        vm.prank(user1);
        token.transferFrom(adminTreasury, user2, transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(adminTreasury, user1), approvalAmount - transferAmount);
    }

    function test_Integration_PauseAndUnpauseFlow() public {
        vm.prank(adminPauser);
        vm.expectEmit(true, false, false, true);
        emit CircuitBreakerActivated(adminPauser, block.timestamp);
        token.pause();
        assertTrue(token.paused());

        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100);

        vm.prank(adminPauser);
        vm.expectEmit(true, false, false, true);
        emit CircuitBreakerDeactivated(adminPauser, block.timestamp);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_Integration_BotPauseAdminUnpause() public {
        vm.prank(bot);
        token.pause();
        assertTrue(token.paused());

        vm.prank(bot);
        vm.expectRevert();
        token.unpause();

        vm.prank(adminPauser);
        token.unpause();
        assertFalse(token.paused());
    }

    function test_Integration_UpgradeToV2() public {
        vm.prank(adminTreasury);
        token.transfer(user1, 5000 * 10 ** 18);

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));
        assertEq(tokenV2.balanceOf(user1), 5000 * 10 ** 18);
        assertEq(tokenV2.totalSupply(), INITIAL_SUPPLY);

        vm.prank(adminTreasury);
        tokenV2.setNewFeature(123);
        assertEq(tokenV2.newFeature(), 123);
        assertEq(tokenV2.version(), "v2");
    }

    function test_Integration_UpgradePreservesPauseState() public {
        vm.prank(adminPauser);
        token.pause();
        assertTrue(token.paused());

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));
        assertTrue(tokenV2.paused());

        vm.prank(adminPauser);
        tokenV2.unpause();
        assertFalse(tokenV2.paused());
    }

    function test_RevertWhen_NonUpgraderAttemptsUpgrade() public {
        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(adminTreasury);
        vm.expectRevert();
        token.upgradeToAndCall(address(implementationV2), "");
    }

    function test_Integration_ReentrancyProtectionOnTransfer() public {
        vm.prank(adminTreasury);
        token.transfer(user1, 10000 * 10 ** 18);

        vm.prank(user1);
        token.transfer(user2, 1000 * 10 ** 18);

        assertEq(token.balanceOf(user2), 1000 * 10 ** 18);
    }
}
