// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title NEBAToken
 * @author NEBA Team
 * @notice ERC-20 token with pausable transfers, UUPS upgradeability, and role-based access control.
 * @dev Phase 1 implementation with hardened security and compliance features
 *
 * Key Features:
 * - Fixed supply of 1 billion tokens
 * - UUPS upgradeable proxy pattern
 * - Role-based access control (Admin, Upgrader, Admin Pauser, Bot Pauser)
 * - Pausable transfers for emergency controls
 * - Reentrancy protection
 * - DEFAULT_ADMIN_ROLE can grant roles
 * - ADMIN_PAUSER_ROLE can pause and unpause the token
 * - BOT_PAUSER_ROLE can pause the token for bots
 * - UPGRADER_ROLE can upgrade the contract
 */
contract NEBAToken is
    ERC20Upgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
    bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    // Storage gap for safe upgrades
    uint256[50] private __gap;

    event CircuitBreakerActivated(address indexed by, uint256 timestamp);
    event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);

    error ZeroAddress();
    error UnauthorizedPauser();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyPausers() {
        if (
            !hasRole(ADMIN_PAUSER_ROLE, msg.sender) &&
            !hasRole(BOT_PAUSER_ROLE, msg.sender)
        ) {
            revert UnauthorizedPauser();
        }
        _;
    }

    /**
     * @notice Initializes the NEBA Token contract and grants roles to the adminTreasury
     * DEFAULT_ADMIN_ROLE has all permissions and it can grant and revoke roles
     * ADMIN_PAUSER_ROLE and BOT_PAUSER_ROLE have the ability to pause and unpause the token
     * BOT_PAUSER_ROLE has the ability to pause the token for bots
     * UPGRADER_ROLE has the ability to upgrade the contract
     * @param adminTreasury Address for day-to-day management (admin, pauser).
     * @param upgraderAddress Address that can upgrade the contract (should be a separate, high-security multisig/wallet).
     * @param botAddress Address for the automated keeper bot (can only pause).
     * @dev Mints entire supply to adminTreasury and sets up roles
     */
    function initialize(
        address adminTreasury,
        address upgraderAddress,
        address botAddress
    ) public initializer {
        if (adminTreasury == address(0)) revert ZeroAddress();
        if (upgraderAddress == address(0)) revert ZeroAddress();
        if (botAddress == address(0)) revert ZeroAddress();

        __ERC20_init("NEBA Token", "NEBA");
        __ERC20Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, adminTreasury);
        _grantRole(ADMIN_PAUSER_ROLE, adminTreasury);
        _grantRole(BOT_PAUSER_ROLE, botAddress);
        _grantRole(UPGRADER_ROLE, upgraderAddress);

        _mint(adminTreasury, INITIAL_SUPPLY);
    }

    /**
     * @notice Pauses token transfers by ADMIN_PAUSER_ROLE or BOT_PAUSER_ROLE
     * @dev Can only be called by ADMIN_PAUSER_ROLE and BOT_PAUSER_ROLE.
     */
    function pause() external onlyPausers whenNotPaused {
        _pause();
        emit CircuitBreakerActivated(msg.sender, block.timestamp);
    }

    /**
     * @notice Unpauses token transfers by ADMIN_PAUSER_ROLE
     * @dev Can only be called by ADMIN_PAUSER_ROLE.
     */
    function unpause() external onlyRole(ADMIN_PAUSER_ROLE) whenPaused {
        _unpause();
        emit CircuitBreakerDeactivated(msg.sender, block.timestamp);
    }

    /**
     * @notice Authorizes contract upgrades (UUPS pattern).
     * @param newImplementation Address of new implementation contract
     * @dev Restricted to UPGRADER_ROLE only
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @notice Internal function to update token balances
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @dev Enforces pause state for transfers.
     */
    function _update(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
        whenNotPaused
    {
        super._update(from, to, amount);
    }

    /**
     * @notice Override to prevent approvals while the contract is paused.
     * @param owner Token owner
     * @param spender Address allowed to spend
     * @param value Amount approved
     */
    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual override whenNotPaused {
        super._approve(owner, spender, value, emitEvent);
    }
}
