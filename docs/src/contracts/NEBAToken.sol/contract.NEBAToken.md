# NEBAToken
[Git Source](https://github.com/JayP11/NEBA-Token/blob/01a7056d355b48bc54ba93024841b8009eb75fc3/contracts/NEBAToken.sol)

**Inherits:**
ERC20Upgradeable, ERC20PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable

**Author:**
NEBA Team

ERC-20 token with pausable transfers, UUPS upgradeability, and role-based access control.

*Phase 1 implementation with hardened security and compliance features
Key Features:
- Fixed supply of 1 billion tokens
- UUPS upgradeable proxy pattern
- Role-based access control (Admin, Upgrader, Admin Pauser, Bot Pauser)
- Pausable transfers for emergency controls
- Reentrancy protection
- ADMIN_PAUSER_ROLE can pause and unpause the token and grant roles to other addresses
- BOT_PAUSER_ROLE can pause the token for bots
- UPGRADER_ROLE can upgrade the contract*


## State Variables
### UPGRADER_ROLE

```solidity
bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
```


### ADMIN_PAUSER_ROLE

```solidity
bytes32 public constant ADMIN_PAUSER_ROLE = keccak256("ADMIN_PAUSER_ROLE");
```


### BOT_PAUSER_ROLE

```solidity
bytes32 public constant BOT_PAUSER_ROLE = keccak256("BOT_PAUSER_ROLE");
```


### INITIAL_SUPPLY

```solidity
uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;
```


### __gap

```solidity
uint256[50] private __gap;
```


## Functions
### constructor

**Note:**
oz-upgrades-unsafe-allow: constructor


```solidity
constructor();
```

### onlyPausers


```solidity
modifier onlyPausers();
```

### initialize

Initializes the NEBA Token contract and grants roles to the adminTreasury
DEFAULT_ADMIN_ROLE has all permissions and it can grant and revoke roles
ADMIN_PAUSER_ROLE and BOT_PAUSER_ROLE have the ability to pause and unpause the token
BOT_PAUSER_ROLE has the ability to pause the token for bots
UPGRADER_ROLE has the ability to upgrade the contract

*Mints entire supply to adminTreasury and sets up roles*


```solidity
function initialize(address adminTreasury, address upgraderAddress, address botAddress) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`adminTreasury`|`address`|Address for day-to-day management (admin, pauser).|
|`upgraderAddress`|`address`|Address that can upgrade the contract (should be a separate, high-security multisig/wallet).|
|`botAddress`|`address`|Address for the automated keeper bot (can only pause).|


### pause

Pauses token transfers by ADMIN_PAUSER_ROLE or BOT_PAUSER_ROLE

*Can only be called by ADMIN_PAUSER_ROLE and BOT_PAUSER_ROLE.*


```solidity
function pause() external onlyPausers whenNotPaused;
```

### unpause

Unpauses token transfers by ADMIN_PAUSER_ROLE

*Can only be called by ADMIN_PAUSER_ROLE.*


```solidity
function unpause() external onlyRole(ADMIN_PAUSER_ROLE) whenPaused;
```

### _authorizeUpgrade

Authorizes contract upgrades (UUPS pattern).

*Restricted to UPGRADER_ROLE only*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|Address of new implementation contract|


### _update

Internal function to update token balances

*Enforces pause state for transfers.*


```solidity
function _update(address from, address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable)
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|Sender address|
|`to`|`address`|Recipient address|
|`amount`|`uint256`|Amount to transfer|


### _approve

Override to prevent approvals while the contract is paused.


```solidity
function _approve(address owner, address spender, uint256 value, bool emitEvent)
    internal
    virtual
    override
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|Token owner|
|`spender`|`address`|Address allowed to spend|
|`value`|`uint256`|Amount approved|
|`emitEvent`|`bool`||


## Events
### CircuitBreakerActivated

```solidity
event CircuitBreakerActivated(address indexed by, uint256 timestamp);
```

### CircuitBreakerDeactivated

```solidity
event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);
```

## Errors
### ZeroAddress

```solidity
error ZeroAddress();
```

### UnauthorizedPauser

```solidity
error UnauthorizedPauser();
```

