// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {NEBAToken} from "../contracts/NEBAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NEBATokenTest is Test {
    NEBAToken public implementation;
    NEBAToken public nebaToken;
    ERC1967Proxy public proxy;

    address public adminTreasury = makeAddr("adminTreasury");
    address public upgraderAddress = makeAddr("upgraderAddress");
    address public botAddress = makeAddr("botAddress");

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    function setUp() public {
        implementation = new NEBAToken();

        bytes memory data =
            abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, upgraderAddress, botAddress);

        proxy = new ERC1967Proxy(address(implementation), data);
        nebaToken = NEBAToken(address(proxy));
    }

    function test_initialize() public view {
        assertEq(nebaToken.name(), "NEBA Token");
        assertEq(nebaToken.symbol(), "NEBA");
        assertEq(nebaToken.decimals(), 18);
        assertEq(nebaToken.paused(), false);
        assertEq(nebaToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(nebaToken.balanceOf(adminTreasury), INITIAL_SUPPLY);
        assertEq(nebaToken.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury), true);
        assertEq(nebaToken.hasRole(ADMIN_PAUSER_ROLE, adminTreasury), true);
        assertEq(nebaToken.hasRole(BOT_PAUSER_ROLE, botAddress), true);
        assertEq(nebaToken.hasRole(UPGRADER_ROLE, upgraderAddress), true);
    }

    function test_revertWhen_initializeWithZeroAddress() public {
        NEBAToken newImpl = new NEBAToken();
        bytes memory data =
            abi.encodeWithSelector(NEBAToken.initialize.selector, address(0), upgraderAddress, botAddress);
        vm.expectRevert(NEBAToken.ZeroAddress.selector);
        new ERC1967Proxy(address(newImpl), data);
    }

    function test_revertWhen_initializeWithZeroUpgraderAddress() public {
        NEBAToken newImpl = new NEBAToken();
        bytes memory data = abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, address(0), botAddress);
        vm.expectRevert(NEBAToken.ZeroAddress.selector);
        new ERC1967Proxy(address(newImpl), data);
    }

    function test_revertWhen_initializeWithZeroBotAddress() public {
        NEBAToken newImpl = new NEBAToken();
        bytes memory data =
            abi.encodeWithSelector(NEBAToken.initialize.selector, adminTreasury, upgraderAddress, address(0));
        vm.expectRevert(NEBAToken.ZeroAddress.selector);
        new ERC1967Proxy(address(newImpl), data);
    }

    function test_Initialize_CannotReinitialize() public {
        vm.expectRevert();
        nebaToken.initialize(adminTreasury, upgraderAddress, botAddress);
    }

    function test_Implementation_IsDisabled() public {
        vm.expectRevert();
        implementation.initialize(adminTreasury, upgraderAddress, botAddress);
    }

    function test_Upgrade_PreservesState() public {
        vm.prank(adminTreasury);
        nebaToken.transfer(user1, 1000 ether);

        uint256 balanceBefore = nebaToken.balanceOf(user1);
        uint256 totalSupplyBefore = nebaToken.totalSupply();

        NEBAToken newImpl = new NEBAToken();
        vm.prank(upgraderAddress);
        nebaToken.upgradeToAndCall(address(newImpl), "");

        assertEq(nebaToken.balanceOf(user1), balanceBefore);
        assertEq(nebaToken.totalSupply(), totalSupplyBefore);
    }

    function test_Upgrade_PreservesRoles() public {
        NEBAToken newImpl = new NEBAToken();
        vm.prank(upgraderAddress);
        nebaToken.upgradeToAndCall(address(newImpl), "");

        assertTrue(nebaToken.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury));
        assertTrue(nebaToken.hasRole(UPGRADER_ROLE, upgraderAddress));
        assertTrue(nebaToken.hasRole(BOT_PAUSER_ROLE, botAddress));
    }

    function test_Upgrade_CannotDowngradeToOldImplementation() public {
        address oldImpl = address(implementation);

        NEBAToken newImpl = new NEBAToken();
        vm.prank(upgraderAddress);
        nebaToken.upgradeToAndCall(address(newImpl), "");

        vm.prank(upgraderAddress);
        nebaToken.upgradeToAndCall(oldImpl, "");

        assertEq(nebaToken.totalSupply(), INITIAL_SUPPLY);
    }

    function test_RoleManagement_AdminCanGrantAndRevokeRoles() public {
        vm.prank(adminTreasury);
        nebaToken.grantRole(BOT_PAUSER_ROLE, user1);
        assertTrue(nebaToken.hasRole(BOT_PAUSER_ROLE, user1));

        vm.prank(adminTreasury);
        nebaToken.revokeRole(BOT_PAUSER_ROLE, user1);
        assertFalse(nebaToken.hasRole(BOT_PAUSER_ROLE, user1));
    }

    //  PAUSE TESTS

    function test_pause() public {
        vm.prank(adminTreasury);
        nebaToken.pause();
        assertEq(nebaToken.paused(), true);
    }

    function test_pauseBy_botAddress() public {
        vm.prank(botAddress);
        nebaToken.pause();
        assertEq(nebaToken.paused(), true);
    }

    function test_unpause_by_botAddress() public {
        vm.prank(botAddress);
        nebaToken.pause();

        vm.prank(botAddress);
        vm.expectRevert();
        nebaToken.unpause();
    }

    function test_revertWhen_pauseBy_nonPauser() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(NEBAToken.UnauthorizedPauser.selector));
        nebaToken.pause();
    }

    function testCannotPauseWhenAlreadyPaused() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(adminTreasury);
        vm.expectRevert();
        nebaToken.pause();
    }

    function test_unpause() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(adminTreasury);
        nebaToken.unpause();
        assertEq(nebaToken.paused(), false);
    }

    function test_revertWhen_unpauseBy_OtherAddress() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(botAddress);
        vm.expectRevert();
        nebaToken.unpause();
    }

    function testCannotUnPauseWhenAlreadyUnPaused() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(adminTreasury);
        nebaToken.unpause();

        vm.prank(adminTreasury);
        vm.expectRevert();
        nebaToken.unpause();
    }

    // UPGRADE TESTS

    function test_Upgrade_AccessControl() public {
        NEBAToken newImplementation = new NEBAToken();

        vm.prank(upgraderAddress);
        nebaToken.upgradeToAndCall(address(newImplementation), "");
        assertEq(nebaToken.totalSupply(), INITIAL_SUPPLY);

        vm.prank(adminTreasury);
        vm.expectRevert();
        nebaToken.upgradeToAndCall(address(newImplementation), "");
    }

    // TRANSFER TESTS

    function test_Transfer_RevertIf_Paused() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(adminTreasury);
        vm.expectRevert();
        nebaToken.transfer(user1, 100 * 10 ** 18);
    }

    function test_Approve_RevertIf_Paused() public {
        vm.prank(adminTreasury);
        nebaToken.pause();

        vm.prank(adminTreasury);
        vm.expectRevert();
        nebaToken.approve(user1, 100 * 10 ** 18);
    }

    function test_Transfer_Success() public {
        uint256 beforeBalance = nebaToken.balanceOf(user1);

        vm.prank(adminTreasury);
        nebaToken.transfer(user1, 100 ether);

        uint256 afterBalance = nebaToken.balanceOf(user1);
        assertEq(afterBalance, beforeBalance + 100 ether);
    }

    function test_Approve_Success() public {
        vm.prank(adminTreasury);
        nebaToken.approve(user1, 100 * 10 ** 18);
        assertEq(nebaToken.allowance(adminTreasury, user1), 100 * 10 ** 18);
    }

    function test_TransferFrom_Success() public {
        vm.startPrank(adminTreasury);
        nebaToken.transfer(user1, 1000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(user1);
        nebaToken.approve(user2, 500 * 10 ** 18);

        vm.prank(user2);
        nebaToken.transferFrom(user1, user3, 100 * 10 ** 18);
        assertEq(nebaToken.balanceOf(user3), 100 * 10 ** 18);
    }
}
