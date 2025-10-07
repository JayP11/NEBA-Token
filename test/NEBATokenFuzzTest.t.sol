// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/NEBAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NEBATokenFuzzTest is Test {
    NEBAToken public token;
    NEBAToken public implementation;

    address public adminTreasury;
    address public upgraderAddress;
    address public adminPauserAddress;
    address public botAddress;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgraderAddress = makeAddr("upgraderAddress");
        adminPauserAddress = makeAddr("adminPauserAddress");
        botAddress = makeAddr("botAddress");

        implementation = new NEBAToken();

        bytes memory initData = abi.encodeWithSelector(
            NEBAToken.initialize.selector, adminTreasury, upgraderAddress, adminPauserAddress, botAddress
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        token = NEBAToken(address(proxy));
    }

    // ========== TRANSFER FUZZ TESTS ==========

    function testFuzz_Transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to != adminTreasury); // Avoid self-transfer complexity

        amount = bound(amount, 0, token.balanceOf(adminTreasury));

        uint256 adminBalanceBefore = token.balanceOf(adminTreasury);
        uint256 toBalanceBefore = token.balanceOf(to);

        vm.prank(adminTreasury);
        bool success = token.transfer(to, amount);

        assertTrue(success);
        assertEq(token.balanceOf(to), toBalanceBefore + amount);
        assertEq(token.balanceOf(adminTreasury), adminBalanceBefore - amount);

        // Invariant: total supply unchanged
        assertEq(token.totalSupply(), 1_000_000_000e18);
    }

    function testFuzz_TransferFrom(address from, address to, uint256 amount) public {
        vm.assume(from != address(0) && to != address(0));
        vm.assume(from != to);

        // Fund 'from' first by transferring from adminTreasury
        uint256 fundAmount = 1000e18;
        vm.prank(adminTreasury);
        token.transfer(from, fundAmount);

        amount = bound(amount, 0, fundAmount);
        uint256 before = token.balanceOf(to);

        vm.prank(from);
        token.approve(address(this), amount);

        bool success = token.transferFrom(from, to, amount);

        assertTrue(success);
        assertEq(token.balanceOf(to), before + amount);
    }

    // ========== APPROVE FUZZ TESTS ==========

    function testFuzz_Approve(address spender, uint256 amount) public {
        vm.assume(spender != address(0));

        vm.prank(adminTreasury);
        bool success = token.approve(spender, amount);

        assertTrue(success);
        assertEq(token.allowance(adminTreasury, spender), amount);
    }

    // ========== PAUSE/UNPAUSE FUZZ TESTS ==========

    function testFuzz_PauseByAdminPauser(address caller) public {
        vm.assume(caller != address(0));

        vm.prank(adminTreasury);
        token.grantRole(ADMIN_PAUSER_ROLE, caller);

        vm.prank(caller);
        token.pause();

        assertTrue(token.paused());
    }

    function testFuzz_PauseByBotPauser(address caller) public {
        vm.assume(caller != address(0));

        vm.prank(adminTreasury);
        token.grantRole(BOT_PAUSER_ROLE, caller);

        vm.prank(caller);
        token.pause();

        assertTrue(token.paused());
    }

    function testFuzz_UnpauseByAdminPauser(address caller) public {
        vm.assume(caller != address(0));

        vm.prank(adminPauserAddress);
        token.pause();

        vm.prank(adminTreasury);
        token.grantRole(ADMIN_PAUSER_ROLE, caller);

        vm.prank(caller);
        token.unpause();

        assertFalse(token.paused());
    }

    function testFuzz_PauseRevertUnauthorized(address caller) public {
        vm.assume(caller != address(0));
        vm.assume(!token.hasRole(ADMIN_PAUSER_ROLE, caller));
        vm.assume(!token.hasRole(BOT_PAUSER_ROLE, caller));

        vm.prank(caller);
        vm.expectRevert(NEBAToken.UnauthorizedPauser.selector);
        token.pause();
    }

    // ========== VIEW FUNCTIONS FUZZ TESTS ==========

    function testFuzz_BalanceOf(address account) public view {
        token.balanceOf(account);
    }

    function testFuzz_Allowance(address owner, address spender) public view {
        token.allowance(owner, spender);
    }

    function testFuzz_TotalSupply() public view {
        assertEq(token.totalSupply(), 1_000_000_000e18);
    }

    // ========== PAUSED STATE FUZZ TESTS ==========

    function testFuzz_TransferRevertWhenPaused(address to, uint256 amount) public {
        vm.assume(to != address(0));

        vm.prank(adminPauserAddress);
        token.pause();

        amount = bound(amount, 1, token.balanceOf(adminTreasury));

        vm.prank(adminTreasury);
        vm.expectRevert();
        token.transfer(to, amount);
    }

    function testFuzz_ApproveRevertWhenPaused(address spender, uint256 amount) public {
        vm.assume(spender != address(0));

        vm.prank(adminPauserAddress);
        token.pause();

        vm.prank(adminTreasury);
        vm.expectRevert();
        token.approve(spender, amount);
    }
}
