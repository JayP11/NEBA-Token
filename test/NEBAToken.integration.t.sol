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
    address public bot;
    address public investor;
    address public user1;
    address public user2;
    address public user3;
    address public maliciousActor;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");
    bytes32 public constant BLOCKLIST_MANAGER_ROLE =
        keccak256("BLOCKLIST_MANAGER_ROLE");

    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 constant INVESTOR_ALLOCATION = 600_000_000 * 10 ** 18;
    uint256 constant ADMIN_ALLOCATION = 400_000_000 * 10 ** 18;

    event AddressBlocklisted(address indexed account, uint256 timestamp);
    event AddressUnblocklisted(address indexed account, uint256 timestamp);
    event CircuitBreakerActivated(address indexed by, uint256 timestamp);
    event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);
    event TokensDistributed(
        address indexed investor,
        uint256 amount,
        uint256 timestamp
    );

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgrader = makeAddr("upgrader");
        bot = makeAddr("bot");
        investor = makeAddr("investor");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        maliciousActor = makeAddr("maliciousActor");

        implementation = new NEBAToken();

        bytes memory initData = abi.encodeWithSelector(
            NEBAToken.initialize.selector,
            adminTreasury,
            upgrader,
            bot,
            investor
        );

        proxy = new ERC1967Proxy(address(implementation), initData);
        token = NEBAToken(address(proxy));
    }

    function test_Integration_InitialDeployment() public view {
        assertEq(token.name(), "NEBA Token");
        assertEq(token.symbol(), "NEBA");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(investor), INVESTOR_ALLOCATION);
        assertEq(token.balanceOf(adminTreasury), ADMIN_ALLOCATION);
        assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury));
        assertTrue(token.hasRole(ADMIN_PAUSER_ROLE, adminTreasury));
        assertTrue(token.hasRole(BOT_PAUSER_ROLE, bot));
        assertTrue(token.hasRole(UPGRADER_ROLE, upgrader));
        assertTrue(token.hasRole(BLOCKLIST_MANAGER_ROLE, adminTreasury));
    }

    function test_Integration_NormalTransferFlow() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.startPrank(investor);
        token.transfer(user1, transferAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(
            token.balanceOf(investor),
            INVESTOR_ALLOCATION - transferAmount
        );

        vm.startPrank(user1);
        token.transfer(user2, transferAmount / 2);
        vm.stopPrank();

        assertEq(token.balanceOf(user2), transferAmount / 2);
        assertEq(token.balanceOf(user1), transferAmount / 2);
    }

    function test_Integration_ApprovalAndTransferFromFlow() public {
        uint256 approvalAmount = 5000 * 10 ** 18;
        uint256 transferAmount = 3000 * 10 ** 18;

        vm.prank(investor);
        token.approve(user1, approvalAmount);

        assertEq(token.allowance(investor, user1), approvalAmount);

        vm.prank(user1);
        token.transferFrom(investor, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(
            token.allowance(investor, user1),
            approvalAmount - transferAmount
        );
    }

    function test_Integration_AdminPauseAndUnpauseFlow() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.prank(investor);
        token.transfer(user1, transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);

        vm.prank(adminTreasury);
        vm.expectEmit(true, false, false, true);
        emit CircuitBreakerActivated(adminTreasury, block.timestamp);
        token.pause();

        assertTrue(token.paused());

        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, transferAmount);

        vm.prank(adminTreasury);
        vm.expectEmit(true, false, false, true);
        emit CircuitBreakerDeactivated(adminTreasury, block.timestamp);
        token.unpause();

        assertFalse(token.paused());

        vm.prank(user1);
        token.transfer(user2, transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
    }

    function test_Integration_BotPauseAdminUnpauseFlow() public {
        vm.prank(bot);
        vm.expectEmit(true, false, false, true);
        emit CircuitBreakerActivated(bot, block.timestamp);
        token.pause();

        assertTrue(token.paused());

        vm.prank(bot);
        vm.expectRevert();
        token.unpause();

        vm.prank(adminTreasury);
        token.unpause();

        assertFalse(token.paused());
    }

    function test_Integration_EmergencyPauseMultipleActorsFlow() public {
        vm.prank(investor);
        token.transfer(user1, 10000 * 10 ** 18);

        vm.prank(bot);
        token.pause();

        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 100 * 10 ** 18);

        vm.prank(investor);
        vm.expectRevert();
        token.transfer(user3, 100 * 10 ** 18);

        vm.prank(adminTreasury);
        token.unpause();

        vm.prank(user1);
        token.transfer(user2, 100 * 10 ** 18);
        assertEq(token.balanceOf(user2), 100 * 10 ** 18);
    }

    function test_Integration_BlocklistSingleAddressFlow() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.prank(investor);
        token.transfer(user1, transferAmount);

        vm.prank(user1);
        token.transfer(user2, 100 * 10 ** 18);
        assertEq(token.balanceOf(user2), 100 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;

        vm.prank(adminTreasury);
        vm.expectEmit(true, false, false, true);
        emit AddressBlocklisted(user1, block.timestamp);
        token.addToBlocklistBatch(accounts);

        assertTrue(token.isBlocklisted(user1));

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.transfer(user2, 100 * 10 ** 18);

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.transfer(user1, 50 * 10 ** 18);

        vm.prank(adminTreasury);
        vm.expectEmit(true, false, false, true);
        emit AddressUnblocklisted(user1, block.timestamp);
        token.removeFromBlocklistBatch(accounts);

        assertFalse(token.isBlocklisted(user1));

        vm.prank(user1);
        token.transfer(user2, 100 * 10 ** 18);
        assertEq(token.balanceOf(user2), 200 * 10 ** 18);
    }

    function test_Integration_BlocklistMultipleAddressesFlow() public {
        vm.startPrank(investor);
        token.transfer(user1, 10000 * 10 ** 18);
        token.transfer(user2, 10000 * 10 ** 18);
        token.transfer(user3, 10000 * 10 ** 18);
        vm.stopPrank();

        address[] memory accounts = new address[](2);
        accounts[0] = user1;
        accounts[1] = user2;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        assertTrue(token.isBlocklisted(user1));
        assertTrue(token.isBlocklisted(user2));
        assertFalse(token.isBlocklisted(user3));

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.transfer(user3, 100 * 10 ** 18);

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user2)
        );
        token.transfer(user3, 100 * 10 ** 18);

        vm.prank(user3);
        token.transfer(investor, 1000 * 10 ** 18);
        assertEq(
            token.balanceOf(investor),
            INVESTOR_ALLOCATION - 30000 * 10 ** 18 + 1000 * 10 ** 18
        );
    }

    function test_Integration_BlocklistPreventsApprovals() public {
        vm.prank(investor);
        token.transfer(user1, 10000 * 10 ** 18);

        vm.prank(user1);
        token.approve(user2, 5000 * 10 ** 18);
        assertEq(token.allowance(user1, user2), 5000 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.approve(user2, 1000 * 10 ** 18);

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.transferFrom(user1, user3, 1000 * 10 ** 18);
    }

    function test_Integration_BlocklistDuringPause() public {
        vm.prank(investor);
        token.transfer(user1, 10000 * 10 ** 18);

        vm.prank(adminTreasury);
        token.pause();

        address[] memory accounts = new address[](1);
        accounts[0] = user1;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        assertTrue(token.isBlocklisted(user1));
        assertTrue(token.paused());

        vm.prank(adminTreasury);
        token.unpause();

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        token.transfer(user2, 100 * 10 ** 18);
    }

    function test_Integration_RoleManagementFlow() public {
        address newAdmin = makeAddr("newAdmin");
        address newBlocklistManager = makeAddr("newBlocklistManager");

        vm.prank(adminTreasury);
        token.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        assertTrue(token.hasRole(DEFAULT_ADMIN_ROLE, newAdmin));

        vm.prank(newAdmin);
        token.grantRole(BLOCKLIST_MANAGER_ROLE, newBlocklistManager);

        assertTrue(token.hasRole(BLOCKLIST_MANAGER_ROLE, newBlocklistManager));

        address[] memory accounts = new address[](1);
        accounts[0] = maliciousActor;

        vm.prank(newBlocklistManager);
        token.addToBlocklistBatch(accounts);

        assertTrue(token.isBlocklisted(maliciousActor));

        vm.prank(adminTreasury);
        token.revokeRole(DEFAULT_ADMIN_ROLE, newAdmin);

        assertFalse(token.hasRole(DEFAULT_ADMIN_ROLE, newAdmin));
    }

    function test_Integration_PermitAndTransferFromFlow() public {
        uint256 ownerPrivateKey = 0xA11CE;
        address owner = vm.addr(ownerPrivateKey);

        vm.prank(investor);
        token.transfer(owner, 10000 * 10 ** 18);

        uint256 permitAmount = 5000 * 10 ** 18;
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                owner,
                user1,
                permitAmount,
                token.nonces(owner),
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.prank(user1);
        token.permit(owner, user1, permitAmount, deadline, v, r, s);

        assertEq(token.allowance(owner, user1), permitAmount);
        assertEq(token.nonces(owner), 1);

        vm.prank(user1);
        token.transferFrom(owner, user2, 3000 * 10 ** 18);

        assertEq(token.balanceOf(user2), 3000 * 10 ** 18);
        assertEq(token.allowance(owner, user1), 2000 * 10 ** 18);
    }

    function test_Integration_UpgradeToV2Flow() public {
        uint256 user1BalanceBefore = 5000 * 10 ** 18;
        vm.prank(investor);
        token.transfer(user1, user1BalanceBefore);

        uint256 totalSupplyBefore = token.totalSupply();
        assertEq(token.balanceOf(user1), user1BalanceBefore);

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();

        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));

        assertEq(tokenV2.totalSupply(), totalSupplyBefore);
        assertEq(tokenV2.balanceOf(user1), user1BalanceBefore);
        assertEq(tokenV2.name(), "NEBA Token");
        assertEq(tokenV2.symbol(), "NEBA");

        assertTrue(tokenV2.hasRole(DEFAULT_ADMIN_ROLE, adminTreasury));
        assertTrue(tokenV2.hasRole(UPGRADER_ROLE, upgrader));

        vm.prank(adminTreasury);
        tokenV2.setNewFeature(12345);
        assertEq(tokenV2.newFeature(), 12345);
        assertEq(tokenV2.version(), "v2");

        vm.prank(user1);
        tokenV2.transfer(user2, 1000 * 10 ** 18);
        assertEq(tokenV2.balanceOf(user2), 1000 * 10 ** 18);
    }

    function test_Integration_UpgradePreservesBlocklist() public {
        vm.prank(investor);
        token.transfer(user1, 5000 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);
        assertTrue(token.isBlocklisted(user1));

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));

        assertTrue(tokenV2.isBlocklisted(user1));

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        tokenV2.transfer(user2, 100 * 10 ** 18);
    }

    function test_Integration_UpgradePreservesPauseState() public {
        vm.prank(adminTreasury);
        token.pause();
        assertTrue(token.paused());

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));

        assertTrue(tokenV2.paused());

        vm.prank(investor);
        vm.expectRevert();
        tokenV2.transfer(user1, 100 * 10 ** 18);

        vm.prank(adminTreasury);
        tokenV2.unpause();
        assertFalse(tokenV2.paused());

        vm.prank(investor);
        tokenV2.transfer(user1, 100 * 10 ** 18);
        assertEq(tokenV2.balanceOf(user1), 100 * 10 ** 18);
    }

    function test_RevertWhen_NonUpgraderAttemptsUpgrade() public {
        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();

        vm.prank(adminTreasury);
        vm.expectRevert();
        token.upgradeToAndCall(address(implementationV2), "");

        vm.prank(investor);
        token.transfer(user1, 1000 * 10 ** 18);
        assertEq(token.balanceOf(user1), 1000 * 10 ** 18);
    }

    function test_Integration_CompleteTokenLifecycleScenario() public {
        vm.startPrank(investor);
        token.transfer(user1, 100000 * 10 ** 18);
        token.transfer(user2, 100000 * 10 ** 18);
        token.transfer(user3, 100000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(bot);
        token.pause();

        address[] memory accounts = new address[](1);
        accounts[0] = user3;

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        vm.prank(adminTreasury);
        token.unpause();

        vm.prank(user1);
        token.transfer(user2, 10000 * 10 ** 18);

        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user3)
        );
        token.transfer(user1, 1000 * 10 ** 18);

        NEBATokenV2Mock implementationV2 = new NEBATokenV2Mock();
        vm.prank(upgrader);
        token.upgradeToAndCall(address(implementationV2), "");

        NEBATokenV2Mock tokenV2 = NEBATokenV2Mock(address(token));

        assertTrue(tokenV2.isBlocklisted(user3));
        assertEq(tokenV2.balanceOf(user1), 90000 * 10 ** 18);
        assertEq(tokenV2.balanceOf(user2), 110000 * 10 ** 18);

        vm.prank(adminTreasury);
        tokenV2.setNewFeature(999);
        assertEq(tokenV2.newFeature(), 999);
    }

    function test_Integration_StressTestBlocklistOperations() public {
        uint256 batchSize = 50;
        address[] memory accounts = new address[](batchSize);

        for (uint256 i = 0; i < batchSize; i++) {
            accounts[i] = address(
                uint160(uint256(keccak256(abi.encodePacked("user", i))))
            );
        }

        vm.prank(adminTreasury);
        token.addToBlocklistBatch(accounts);

        for (uint256 i = 0; i < batchSize; i++) {
            assertTrue(token.isBlocklisted(accounts[i]));
        }

        vm.prank(adminTreasury);
        token.removeFromBlocklistBatch(accounts);

        for (uint256 i = 0; i < batchSize; i++) {
            assertFalse(token.isBlocklisted(accounts[i]));
        }
    }

    function test_Integration_ReentrancyProtectionOnTransfer() public {
        vm.prank(investor);
        token.transfer(user1, 10000 * 10 ** 18);

        vm.prank(user1);
        token.transfer(user2, 1000 * 10 ** 18);

        assertEq(token.balanceOf(user2), 1000 * 10 ** 18);
    }
}
