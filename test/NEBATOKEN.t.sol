// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

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
    address public zeroAddress = makeAddr("zeroAddress");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");
    bytes32 public constant BLOCKLIST_MANAGER_ROLE =
        keccak256("BLOCKLIST_MANAGER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    event AddressBlocklisted(address indexed account, uint256 timestamp);
    event AddressUnblocklisted(address indexed account, uint256 timestamp);

    function setUp() public {
        implementation = new NEBAToken();

        bytes memory data = abi.encodeWithSelector(
            NEBAToken.initialize.selector,
            adminTreasury,
            upgraderAddress,
            botAddress
        );

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
        assertEq(
            nebaToken.hasRole(BLOCKLIST_MANAGER_ROLE, adminTreasury),
            true
        );
    }

    function test_revertWhen_initializeWithZeroAddress() public {
        NEBAToken newImpl = new NEBAToken();
        bytes memory data = abi.encodeWithSelector(
            NEBAToken.initialize.selector,
            address(0),
            upgraderAddress,
            botAddress
        );
        vm.expectRevert(NEBAToken.ZeroAddress.selector);
        new ERC1967Proxy(address(newImpl), data);
    }

    function test_Initialize_CannotReinitialize() public {
        vm.expectRevert();
        nebaToken.initialize(adminTreasury, upgraderAddress, botAddress);
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

    function test_revertWhen_pauseBy_nonPauser() public {
        vm.prank(user1);
        vm.expectRevert(
            "Caller must have ADMIN_PAUSER_ROLE or BOT_PAUSER_ROLE"
        );
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

    // BLOCKLIST TESTS

    function testAddToBlocklistBatch_Success() public {
        address[] memory accounts = new address[](2);
        accounts[0] = user1;
        accounts[1] = user2;

        vm.prank(adminTreasury);
        vm.expectEmit(true, false, false, true);
        emit AddressBlocklisted(user1, block.timestamp);
        vm.expectEmit(true, false, false, true);
        emit AddressBlocklisted(user2, block.timestamp);
        nebaToken.addToBlocklistBatch(accounts);

        assertEq(nebaToken.isBlocklisted(user1), true);
        assertEq(nebaToken.isBlocklisted(user2), true);
    }

    function testAddToBlocklistBatch_Revert_InvalidCall() public {
        address[] memory accounts1 = new address[](1);
        accounts1[0] = user1;

        vm.prank(zeroAddress);
        vm.expectRevert();
        nebaToken.addToBlocklistBatch(accounts1);

        address[] memory accounts2 = new address[](2);
        accounts2[0] = user1;
        accounts2[1] = user2;

        vm.prank(user3);
        vm.expectRevert();
        nebaToken.addToBlocklistBatch(accounts2);
    }

    function test_AddToBlocklistBatch_RevertWhen_AlreadyBlocklisted() public {
        address[] memory accounts = new address[](1);
        accounts[0] = user1;

        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(adminTreasury);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.AlreadyBlocklisted.selector, user1)
        );
        nebaToken.addToBlocklistBatch(accounts);
    }

    function testRemoveFromBlocklistBatch_Success() public {
        address[] memory accounts = new address[](2);
        accounts[0] = user1;
        accounts[1] = user2;

        vm.startPrank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.expectEmit(true, false, false, true);
        emit AddressUnblocklisted(user1, block.timestamp);
        vm.expectEmit(true, false, false, true);
        emit AddressUnblocklisted(user2, block.timestamp);
        nebaToken.removeFromBlocklistBatch(accounts);

        assertFalse(nebaToken.isBlocklisted(user1));
        assertFalse(nebaToken.isBlocklisted(user2));
    }

    function testRemoveFromBlocklistBatch_Revert_InvalidCall() public {
        address[] memory accounts1 = new address[](1);
        accounts1[0] = user1;

        vm.prank(zeroAddress);
        vm.expectRevert();
        nebaToken.removeFromBlocklistBatch(accounts1);

        address[] memory accounts2 = new address[](2);
        accounts2[0] = user1;
        accounts2[1] = user2;

        vm.prank(user3);
        vm.expectRevert();
        nebaToken.removeFromBlocklistBatch(accounts2);
    }

    function test_RemoveFromBlocklistBatch_RevertWhen_AlreadyUnBlocklisted()
        public
    {
        address[] memory accounts = new address[](1);
        accounts[0] = user1;

        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(adminTreasury);
        nebaToken.removeFromBlocklistBatch(accounts);

        vm.prank(adminTreasury);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.NotBlocklisted.selector, user1)
        );
        nebaToken.removeFromBlocklistBatch(accounts);
    }

    // TRANSFER TESTS

    function test_Transfer_RevertIf_SenderBlocklisted() public {
        vm.prank(adminTreasury);
        nebaToken.transfer(user1, 1000 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        nebaToken.transfer(user2, 100 * 10 ** 18);
    }

    function test_Transfer_RevertIf_RecipientBlocklisted() public {
        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(adminTreasury);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        nebaToken.transfer(user1, 100 * 10 ** 18);
    }

    function test_Approve_RevertIf_OwnerBlocklisted() public {
        vm.prank(adminTreasury);
        nebaToken.transfer(user1, 1000 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        nebaToken.approve(user2, 100 * 10 ** 18);
    }

    function test_TransferFrom_RevertIf_SenderBlocklisted() public {
        vm.startPrank(adminTreasury);
        nebaToken.transfer(user1, 1000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(user1);
        nebaToken.approve(user2, 500 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user1)
        );
        nebaToken.transferFrom(user1, user2, 100 * 10 ** 18);
    }

    function test_TransferFrom_RevertIf_RecipientBlocklisted() public {
        vm.startPrank(adminTreasury);
        nebaToken.transfer(user1, 1000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(user1);
        nebaToken.approve(user2, 500 * 10 ** 18);

        address[] memory accounts = new address[](1);
        accounts[0] = user2;
        vm.prank(adminTreasury);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.BlocklistedAddress.selector, user2)
        );
        nebaToken.transferFrom(user1, user2, 100 * 10 ** 18);
    }
}
