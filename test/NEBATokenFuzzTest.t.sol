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
    address public botAddress;
    address public investorAddress;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");
    bytes32 public constant BLOCKLIST_MANAGER_ROLE = keccak256("BLOCKLIST_MANAGER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgraderAddress = makeAddr("upgraderAddress");
        botAddress = makeAddr("botAddress");
        investorAddress = makeAddr("investorAddress");

        implementation = new NEBAToken();

        bytes memory initData = abi.encodeWithSelector(
            NEBAToken.initialize.selector, adminTreasury, upgraderAddress, botAddress, investorAddress
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        token = NEBAToken(address(proxy));
    }

    // ========== TRANSFER FUZZ TESTS ==========

    function testFuzz_Transfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(!token.isBlocklisted(to));
        vm.assume(!token.isBlocklisted(investorAddress));

        amount = bound(amount, 0, token.balanceOf(investorAddress));

        vm.prank(investorAddress);
        bool success = token.transfer(to, amount);

        assertTrue(success);
        assertEq(token.balanceOf(to), amount);
    }

    function testFuzz_TransferFrom(address from, address to, uint256 amount) public {
        vm.assume(from != address(0) && to != address(0));
        vm.assume(!token.isBlocklisted(from));
        vm.assume(!token.isBlocklisted(to));
        vm.assume(!token.isBlocklisted(investorAddress));

        vm.prank(investorAddress);
        token.transfer(from, 1000e18);

        amount = bound(amount, 0, token.balanceOf(from));

        vm.prank(from);
        token.approve(address(this), amount);

        bool success = token.transferFrom(from, to, amount);

        assertTrue(success);
        assertEq(token.balanceOf(to), amount);
    }

    // ========== APPROVE FUZZ TESTS ==========

    function testFuzz_Approve(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        vm.assume(!token.isBlocklisted(spender));
        vm.assume(!token.isBlocklisted(investorAddress));

        vm.prank(investorAddress);
        bool success = token.approve(spender, amount);

        assertTrue(success);
        assertEq(token.allowance(investorAddress, spender), amount);
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

        vm.prank(adminTreasury);
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

    // ========== BLOCKLIST FUZZ TESTS ==========

    function testFuzz_AddToBlocklistBatch(address[] calldata accounts) public {
        vm.assume(accounts.length > 0 && accounts.length <= 50);

        address[] memory validAccounts = new address[](accounts.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0) && !token.isBlocklisted(accounts[i])) {
                bool isDuplicate = false;
                for (uint256 j = 0; j < validCount; j++) {
                    if (validAccounts[j] == accounts[i]) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    validAccounts[validCount] = accounts[i];
                    validCount++;
                }
            }
        }

        if (validCount == 0) return;

        address[] memory finalAccounts = new address[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            finalAccounts[i] = validAccounts[i];
        }

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(finalAccounts);

        for (uint256 i = 0; i < validCount; i++) {
            assertTrue(token.isBlocklisted(finalAccounts[i]));
        }
    }

    function testFuzz_RemoveFromBlocklistBatch(address[] calldata accounts) public {
        vm.assume(accounts.length > 0 && accounts.length <= 50);

        address[] memory validAccounts = new address[](accounts.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0)) {
                bool isDuplicate = false;
                for (uint256 j = 0; j < validCount; j++) {
                    if (validAccounts[j] == accounts[i]) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    validAccounts[validCount] = accounts[i];
                    validCount++;
                }
            }
        }

        if (validCount == 0) return;

        address[] memory finalAccounts = new address[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            finalAccounts[i] = validAccounts[i];
        }

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(finalAccounts);

        vm.prank(adminTreasury);
        token.removeFromBlocklistBatch(finalAccounts);

        for (uint256 i = 0; i < validCount; i++) {
            assertFalse(token.isBlocklisted(finalAccounts[i]));
        }
    }

    function testFuzz_IsBlocklisted(address account) public view {
        token.isBlocklisted(account);
    }

    // ========== PERMIT FUZZ TESTS ==========

    function testFuzz_Permit(uint256 ownerPrivateKey, address spender, uint256 amount, uint256 deadline) public {
        ownerPrivateKey = bound(ownerPrivateKey, 1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140);
        address owner = vm.addr(ownerPrivateKey);

        vm.assume(spender != address(0));
        vm.assume(!token.isBlocklisted(owner));
        vm.assume(!token.isBlocklisted(spender));
        deadline = bound(deadline, block.timestamp, type(uint256).max);

        uint256 nonce = token.nonces(owner);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                amount,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(owner, spender, amount, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner), nonce + 1);
    }

    function testFuzz_Nonces(address owner) public view {
        token.nonces(owner);
    }

    // ========== ROLE MANAGEMENT FUZZ TESTS ==========

    function testFuzz_GrantRole(bytes32 role, address account) public {
        vm.assume(account != address(0));
        vm.assume(role != bytes32(0)); // Not DEFAULT_ADMIN_ROLE to avoid circular deps

        vm.prank(adminTreasury);
        token.grantRole(role, account);

        assertTrue(token.hasRole(role, account));
    }

    function testFuzz_RevokeRole(bytes32 role, address account) public {
        vm.assume(account != address(0));
        vm.assume(account != adminTreasury); // Don't revoke from admin

        vm.prank(adminTreasury);
        token.grantRole(role, account);

        vm.prank(adminTreasury);
        token.revokeRole(role, account);

        assertFalse(token.hasRole(role, account));
    }

    function testFuzz_RenounceRole(bytes32 role, address account) public {
        vm.assume(account != address(0));

        vm.prank(adminTreasury);
        token.grantRole(role, account);

        vm.prank(account);
        token.renounceRole(role, account);

        assertFalse(token.hasRole(role, account));
    }

    function testFuzz_HasRole(bytes32 role, address account) public view {
        token.hasRole(role, account);
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

    // ========== BLOCKLIST EDGE CASES ==========

    function testFuzz_TransferRevertBlocklistedSender(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(!token.isBlocklisted(to));

        address[] memory accounts = new address[](1);
        accounts[0] = investorAddress;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        amount = bound(amount, 1, token.balanceOf(investorAddress));

        vm.prank(investorAddress);
        vm.expectRevert(abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, investorAddress));
        token.transfer(to, amount);
    }

    function testFuzz_TransferRevertBlocklistedRecipient(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(!token.isBlocklisted(investorAddress));

        address[] memory accounts = new address[](1);
        accounts[0] = to;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        amount = bound(amount, 1, token.balanceOf(investorAddress));

        vm.prank(investorAddress);
        vm.expectRevert(abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, to));
        token.transfer(to, amount);
    }

    function testFuzz_ApproveRevertBlocklistedOwner(address spender, uint256 amount) public {
        vm.assume(spender != address(0));

        address[] memory accounts = new address[](1);
        accounts[0] = investorAddress;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        vm.prank(investorAddress);
        vm.expectRevert(abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, investorAddress));
        token.approve(spender, amount);
    }

    function testFuzz_ApproveRevertBlocklistedSpender(address spender, uint256 amount) public {
        vm.assume(spender != address(0));
        vm.assume(!token.isBlocklisted(investorAddress));

        address[] memory accounts = new address[](1);
        accounts[0] = spender;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        vm.prank(investorAddress);
        vm.expectRevert(abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, spender));
        token.approve(spender, amount);
    }

    // ========== PAUSED STATE FUZZ TESTS ==========

    function testFuzz_TransferRevertWhenPaused(address to, uint256 amount) public {
        vm.assume(to != address(0));

        vm.prank(adminTreasury);
        token.pause();

        amount = bound(amount, 1, token.balanceOf(investorAddress));

        vm.prank(investorAddress);
        vm.expectRevert();
        token.transfer(to, amount);
    }

    function testFuzz_ApproveRevertWhenPaused(address spender, uint256 amount) public {
        vm.assume(spender != address(0));

        vm.prank(adminTreasury);
        token.pause();

        vm.prank(investorAddress);
        vm.expectRevert();
        token.approve(spender, amount);
    }
}
