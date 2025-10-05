// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {NEBAToken} from "../../contracts/NEBAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NEBATokenInvariant is Test {
    NEBAToken public token;

    address public adminTreasury;
    address public upgrader;
    address public bot;

    address[] public actors;
    mapping(address => bool) public isActor;

    uint256 public ghost_transferCount;
    uint256 public ghost_pauseCount;
    uint256 public ghost_unpauseCount;

    constructor(
        NEBAToken _token,
        address _admin,
        address _upgrader,
        address _bot
    ) {
        token = _token;
        adminTreasury = _admin;
        upgrader = _upgrader;
        bot = _bot;

        _addActor(adminTreasury);
        _addActor(upgrader);
        _addActor(bot);
        _addActor(address(this));
    }

    function transfer(uint256 fromSeed, uint256 toSeed, uint256 amount) public {
        if (actors.length == 0) return;

        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];

        uint256 balance = token.balanceOf(from);
        if (balance == 0) return;
        amount = bound(amount, 0, balance);

        vm.prank(from);
        try token.transfer(to, amount) {
            ghost_transferCount++;
        } catch {}
    }

    function transferToNewAddress(
        uint256 fromSeed,
        address newTo,
        uint256 amount
    ) public {
        if (actors.length == 0) return;
        if (newTo == address(0) || newTo == address(token)) return;

        address from = actors[fromSeed % actors.length];

        _addActor(newTo);

        uint256 balance = token.balanceOf(from);
        if (balance == 0) return;
        amount = bound(amount, 0, balance);

        vm.prank(from);
        try token.transfer(newTo, amount) {
            ghost_transferCount++;
        } catch {}
    }

    function transferFrom(
        uint256 fromSeed,
        uint256 toSeed,
        uint256 spenderSeed,
        uint256 amount
    ) public {
        if (actors.length < 2) return;

        address from = actors[fromSeed % actors.length];
        address to = actors[toSeed % actors.length];
        address spender = actors[spenderSeed % actors.length];

        if (from == spender) return;

        uint256 balance = token.balanceOf(from);
        if (balance == 0) return;
        amount = bound(amount, 0, balance);

        vm.prank(from);
        try token.approve(spender, amount) {} catch {
            return;
        }

        vm.prank(spender);
        try token.transferFrom(from, to, amount) {
            ghost_transferCount++;
        } catch {}
    }

    function pause(uint256 callerSeed) public {
        address caller = actors[callerSeed % actors.length];

        vm.prank(caller);
        try token.pause() {
            ghost_pauseCount++;
        } catch {}
    }

    function unpause(uint256 callerSeed) public {
        address caller = actors[callerSeed % actors.length];

        vm.prank(caller);
        try token.unpause() {
            ghost_unpauseCount++;
        } catch {}
    }

    function _addActor(address actor) internal {
        if (!isActor[actor] && actor != address(0)) {
            actors.push(actor);
            isActor[actor] = true;
        }
    }

    function getActors() external view returns (address[] memory) {
        return actors;
    }

    function getSumOfBalances() public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < actors.length; i++) {
            sum += token.balanceOf(actors[i]);
        }
        return sum;
    }
}

contract NEBATokenAccountingInvariantTest is Test {
    NEBAToken public token;
    NEBATokenInvariant public handler;

    address public adminTreasury;
    address public upgrader;
    address public bot;

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgrader = makeAddr("upgrader");
        bot = makeAddr("bot");

        NEBAToken implementation = new NEBAToken();

        bytes memory initData = abi.encodeWithSelector(
            NEBAToken.initialize.selector,
            adminTreasury,
            upgrader,
            bot
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        token = NEBAToken(address(proxy));

        handler = new NEBATokenInvariant(token, adminTreasury, upgrader, bot);

        vm.prank(adminTreasury);
        token.transfer(address(handler), 100_000 * 10 ** 18);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = NEBATokenInvariant.transfer.selector;
        selectors[1] = NEBATokenInvariant.transferToNewAddress.selector;
        selectors[2] = NEBATokenInvariant.transferFrom.selector;
        selectors[3] = NEBATokenInvariant.pause.selector;
        selectors[4] = NEBATokenInvariant.unpause.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
    }

    function invariant_totalSupplyIsConstant() public view {
        assertEq(
            token.totalSupply(),
            token.INITIAL_SUPPLY(),
            "Total supply changed from initial supply"
        );
    }

    function invariant_sumOfBalancesEqualsTotalSupply() public view {
        uint256 sumBalances = handler.getSumOfBalances();
        uint256 totalSupply = token.totalSupply();

        assertEq(sumBalances, totalSupply, "Sum of balances != total supply");
    }

    function invariant_noBalanceExceedsTotalSupply() public view {
        address[] memory actors = handler.getActors();
        uint256 totalSupply = token.totalSupply();

        for (uint256 i = 0; i < actors.length; i++) {
            uint256 balance = token.balanceOf(actors[i]);
            assertLe(
                balance,
                totalSupply,
                "Individual balance exceeds total supply"
            );
        }
    }

    function invariant_tokenContractHasZeroBalance() public view {
        assertEq(
            token.balanceOf(address(token)),
            0,
            "Token contract holds tokens"
        );
    }

    function invariant_handlerBalanceValid() public view {
        uint256 handlerBalance = token.balanceOf(address(handler));
        assertLe(
            handlerBalance,
            token.totalSupply(),
            "Handler balance exceeds total supply"
        );
    }

    function invariant_callSummary() public view {
        console.log("=== Call Summary ===");
        console.log("Transfers executed:", handler.ghost_transferCount());
        console.log("Pauses executed:", handler.ghost_pauseCount());
        console.log("Unpauses executed:", handler.ghost_unpauseCount());
        console.log("Total actors:", handler.getActors().length);
    }
}

contract NEBATokenHandlerUnitTest is Test {
    NEBAToken public token;
    NEBATokenInvariant public handler;

    address public adminTreasury;
    address public upgrader;
    address public bot;
    address public user1;
    address public user2;

    function setUp() public {
        adminTreasury = makeAddr("adminTreasury");
        upgrader = makeAddr("upgrader");
        bot = makeAddr("bot");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        NEBAToken implementation = new NEBAToken();

        bytes memory initData = abi.encodeWithSelector(
            NEBAToken.initialize.selector,
            adminTreasury,
            upgrader,
            bot
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        token = NEBAToken(address(proxy));

        handler = new NEBATokenInvariant(token, adminTreasury, upgrader, bot);

        vm.prank(adminTreasury);
        token.transfer(address(handler), 100_000 * 10 ** 18);
    }

    function test_Handler_GetActors() public view {
        address[] memory actors = handler.getActors();
        assertGt(actors.length, 0, "Should have actors");

        bool foundAdmin = false;
        bool foundHandler = false;
        for (uint256 i = 0; i < actors.length; i++) {
            if (actors[i] == adminTreasury) foundAdmin = true;
            if (actors[i] == address(handler)) foundHandler = true;
        }
        assertTrue(foundAdmin, "Admin should be in actors");
        assertTrue(foundHandler, "Handler should be in actors");
    }

    function test_Handler_GetSumOfBalances() public view {
        uint256 sum = handler.getSumOfBalances();
        assertEq(sum, token.totalSupply(), "Sum should equal total supply");
    }

    function test_Handler_TransferWithZeroBalance() public {
        handler.transferToNewAddress(0, user2, 0);

        address[] memory actors = handler.getActors();

        uint256 user2Index = 0;
        for (uint256 i = 0; i < actors.length; i++) {
            if (actors[i] == user2) {
                user2Index = i;
                break;
            }
        }

        assertEq(token.balanceOf(user2), 0, "User2 should have zero balance");

        uint256 beforeCount = handler.ghost_transferCount();
        handler.transfer(user2Index, 0, 1000);
        assertEq(
            handler.ghost_transferCount(),
            beforeCount,
            "Transfer count should not increase"
        );
    }

    function test_Handler_TransferToNewAddressZero() public {
        uint256 beforeCount = handler.ghost_transferCount();
        handler.transferToNewAddress(0, address(0), 1000);
        assertEq(
            handler.ghost_transferCount(),
            beforeCount,
            "Should skip zero address"
        );
    }

    function test_Handler_TransferToNewAddressTokenContract() public {
        uint256 beforeCount = handler.ghost_transferCount();
        handler.transferToNewAddress(0, address(token), 1000);
        assertEq(
            handler.ghost_transferCount(),
            beforeCount,
            "Should skip token address"
        );
    }

    function test_Handler_TransferFromInsufficientActors() public {
        NEBAToken newToken = NEBAToken(
            address(
                new ERC1967Proxy(
                    address(new NEBAToken()),
                    abi.encodeWithSelector(
                        NEBAToken.initialize.selector,
                        adminTreasury,
                        upgrader,
                        bot
                    )
                )
            )
        );

        NEBATokenInvariant newHandler = new NEBATokenInvariant(
            newToken,
            adminTreasury,
            upgrader,
            bot
        );

        newHandler.transferFrom(0, 1, 2, 1000);
    }

    function test_Handler_TransferFromSameSender() public {
        vm.prank(adminTreasury);
        token.transfer(user1, 10000 * 10 ** 18);

        handler.transferToNewAddress(0, user1, 1000);

        handler.transferFrom(0, 1, 0, 1000);
    }

    function test_Handler_TransferFromZeroBalance() public {
        handler.transferToNewAddress(0, user2, 0);

        uint256 beforeCount = handler.ghost_transferCount();
        handler.transferFrom(3, 0, 1, 1000);
        assertGe(handler.ghost_transferCount(), beforeCount, "Count tracked");
    }

    function test_Handler_PauseUnauthorized() public {
        handler.transferToNewAddress(0, user1, 100);

        handler.pause(999);
    }

    function test_Handler_UnpauseWhenNotPaused() public {
        assertFalse(token.paused(), "Should not be paused");

        uint256 beforeCount = handler.ghost_unpauseCount();
        handler.unpause(0);
        assertEq(
            handler.ghost_unpauseCount(),
            beforeCount,
            "Unpause should fail"
        );
    }

    function test_Handler_PauseAndUnpauseSuccess() public {
        handler.pause(0);
        assertEq(handler.ghost_pauseCount(), 1, "Pause count should increase");
        assertTrue(token.paused(), "Token should be paused");

        handler.unpause(0);
        assertEq(
            handler.ghost_unpauseCount(),
            1,
            "Unpause count should increase"
        );
        assertFalse(token.paused(), "Token should not be paused");
    }

    function test_Handler_TransferFromApprovalFails() public {
        vm.prank(adminTreasury);
        token.pause();

        uint256 beforeCount = handler.ghost_transferCount();
        handler.transferFrom(0, 1, 2, 1000);
        assertEq(
            handler.ghost_transferCount(),
            beforeCount,
            "Transfer should not occur"
        );

        vm.prank(adminTreasury);
        token.unpause();
    }
}
