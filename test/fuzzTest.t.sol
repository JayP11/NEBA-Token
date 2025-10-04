// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NEBAToken} from "../contracts/NEBAToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract FuzzTest is Test {
    NEBAToken public nebaToken;
    address public admin = makeAddr("admin");
    address public upgrader = makeAddr("upgrader");
    address public bot = makeAddr("bot");

    uint256 constant SUPPLY = 1_000_000_000 * 10 ** 18;

    function setUp() public {
        NEBAToken impl = new NEBAToken();
        bytes memory data = abi.encodeCall(
            NEBAToken.initialize,
            (admin, upgrader, bot)
        );
        nebaToken = NEBAToken(address(new ERC1967Proxy(address(impl), data)));
    }

    function testFuzz_Transfer(address to, uint256 amt) public {
        vm.assume(
            to != address(0) && to != admin && !nebaToken.isBlocklisted(to)
        );
        amt = bound(amt, 1, SUPPLY);

        vm.prank(admin);
        nebaToken.transfer(to, amt);
        assertEq(nebaToken.balanceOf(to), amt);
    }

    function testFuzz_TransferInsufficientBalance(
        address to,
        uint256 amt
    ) public {
        vm.assume(to != address(0) && amt > SUPPLY);
        vm.prank(admin);
        vm.expectRevert();
        nebaToken.transfer(to, amt);
    }

    function testFuzz_Approve(address spender, uint256 amt) public {
        vm.assume(spender != address(0) && !nebaToken.isBlocklisted(spender));
        vm.prank(admin);
        nebaToken.approve(spender, amt);
        assertEq(nebaToken.allowance(admin, spender), amt);
    }

    function testFuzz_TransferFrom(
        address spender,
        address to,
        uint256 amt
    ) public {
        vm.assume(spender != address(0) && to != address(0) && to != admin);
        vm.assume(
            !nebaToken.isBlocklisted(spender) && !nebaToken.isBlocklisted(to)
        );
        amt = bound(amt, 1, SUPPLY);

        vm.prank(admin);
        nebaToken.approve(spender, amt);

        vm.prank(spender);
        nebaToken.transferFrom(admin, to, amt);
        assertEq(nebaToken.balanceOf(to), amt);
    }

    function testFuzz_Blocklist(address account) public {
        vm.assume(account != address(0));

        address[] memory accounts = new address[](1);
        accounts[0] = account;

        vm.prank(admin);
        nebaToken.addToBlocklistBatch(accounts);
        assertTrue(nebaToken.isBlocklisted(account));
    }

    function testFuzz_TransferToBlocklistedFails(
        address account,
        uint256 amt
    ) public {
        vm.assume(account != address(0) && account != admin);
        amt = bound(amt, 1, SUPPLY);

        address[] memory accounts = new address[](1);
        accounts[0] = account;
        vm.prank(admin);
        nebaToken.addToBlocklistBatch(accounts);

        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                NEBAToken.BlocklistedAddress.selector,
                account
            )
        );
        nebaToken.transfer(account, amt);
    }

    function testFuzz_TransferWhenPausedFails(address to, uint256 amt) public {
        vm.assume(to != address(0));
        amt = bound(amt, 1, SUPPLY);

        vm.prank(bot);
        nebaToken.pause();

        vm.prank(admin);
        vm.expectRevert();
        nebaToken.transfer(to, amt);
    }

    function testFuzz_UnauthorizedPause(address attacker) public {
        vm.assume(attacker != admin && attacker != bot);
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(NEBAToken.UnauthorizedPauser.selector)
        );
        nebaToken.pause();
    }

    function testFuzz_UnauthorizedBlocklist(
        address attacker,
        address target
    ) public {
        vm.assume(attacker != admin && target != address(0));

        address[] memory accounts = new address[](1);
        accounts[0] = target;

        vm.prank(attacker);
        vm.expectRevert();
        nebaToken.addToBlocklistBatch(accounts);
    }
}
