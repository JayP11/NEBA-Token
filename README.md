# NEBA Token

A secure, upgradeable ERC-20 token implementation with advanced compliance and governance features, built on OpenZeppelin's battle-tested contracts.

## 🌟 Overview

NEBA Token is a production-ready ERC-20 token with a fixed supply of 1 billion tokens (1,000,000,000 NEBA with 18 decimals). The contract is designed with enterprise-grade security features, compliance tools, and future governance capabilities.

## ✨ Key Features

### 🔒 Security & Compliance

- **UUPS Upgradeable**: Safe contract upgrades with proper authorization
- **Role-Based Access Control**: Granular permissions for different administrative functions
- **Pausable Transfers**: Emergency pause functionality for crisis management
- **Blocklist Management**: Address blocking for compliance and security
- **Reentrancy Protection**: Built-in guards against reentrancy attacks

### 🗳️ Governance Ready

- **ERC20Votes**: Built-in voting capabilities for future governance
- **EIP-2612 Permit**: Gasless approvals for better UX
- **Delegation Support**: Token holders can delegate voting power

### 🛡️ Advanced Features

- **Batch Operations**: Efficient batch blocklist management
- **Custom Errors**: Gas-efficient error handling
- **Storage Gap**: Safe upgrade pattern with reserved storage slots
- **Comprehensive Testing**: Full test coverage with Foundry

## 🏗️ Architecture

### Contract Structure

```
NEBAToken
├── ERC20Upgradeable (Base token functionality)
├── ERC20PausableUpgradeable (Pause/unpause transfers)
├── ERC20PermitUpgradeable (Gasless approvals)
├── ERC20VotesUpgradeable (Voting capabilities)
├── AccessControlUpgradeable (Role management)
├── UUPSUpgradeable (Safe upgrades)
└── ReentrancyGuardUpgradeable (Reentrancy protection)
```

### Role System

- **DEFAULT_ADMIN_ROLE**: Full administrative control
- **ADMIN_PAUSER_ROLE**: Can pause/unpause transfers
- **BOT_PAUSER_ROLE**: Can pause transfers, but cannot unpause (for automated systems)
- **UPGRADER_ROLE**: Can upgrade contract implementation
- **BLOCKLIST_MANAGER_ROLE**: Can manage address blocklist

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for development tools)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd neba-token

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### Deployment

```solidity
// 1. Deploy implementation contract
NEBAToken implementation = new NEBAToken();

// 2. Deploy proxy with initialization
bytes memory initData = abi.encodeWithSelector(
    NEBAToken.initialize.selector,
    adminTreasury,    // Address for day-to-day management
    upgraderAddress,  // Address that can upgrade (multisig recommended)
    botAddress        // Address for automated keeper bot
);

ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
NEBAToken nebaToken = NEBAToken(address(proxy));
```

## 🧪 Testing

The project includes comprehensive tests covering all functionality:

```bash
# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_initialize

# Run tests with verbosity
forge test -vvv
```

### Test Coverage

## 📊 Test Coverage Summary

The NEBA Token contract has comprehensive test coverage with **30 test cases** covering all critical functionality:

### 📈 Coverage Statistics

- **Total Tests**: 30
- **Pass Rate**: 100% (30/30 passed)
- **Test Categories**: 6 major functional areas
- **Gas Optimization**: All functions tested for gas efficiency

### 🧪 Test Categories

#### 1. **Contract Initialization** (3 tests)

- ✅ `test_initialize()` - Verifies proper contract setup
- ✅ `test_revertWhen_initializeWithZeroAddress()` - Zero address validation
- ✅ `test_Initialize_CannotReinitialize()` - Reinitialization protection

#### 2. **Role Management** (1 test)

- ✅ `test_RoleManagement_AdminCanGrantAndRevokeRoles()` - Access control verification

#### 3. **Pause/Unpause Functionality** (8 tests)

- ✅ `test_pause()` - Admin pause capability
- ✅ `test_pauseBy_botAddress()` - Bot pause capability
- ✅ `test_unpause()` - Admin unpause capability
- ✅ `test_unpause_by_botAddress()` - Bot unpause restrictions
- ✅ `test_revertWhen_pauseBy_nonPauser()` - Unauthorized pause prevention
- ✅ `test_revertWhen_unpauseBy_OtherAddress()` - Unauthorized unpause prevention
- ✅ `testCannotPauseWhenAlreadyPaused()` - Double pause prevention
- ✅ `testCannotUnPauseWhenAlreadyUnPaused()` - Double unpause prevention

#### 4. **Blocklist Management** (8 tests)

- ✅ `testAddToBlocklistBatch_Success()` - Batch blocklist addition
- ✅ `testAddToBlocklistBatch_RevertOn_ZeroAddress()` - Zero address validation
- ✅ `testAddToBlocklistBatch_Revert_InvalidCall()` - Unauthorized access prevention
- ✅ `test_AddToBlocklistBatch_RevertWhen_AlreadyBlocklisted()` - Duplicate prevention
- ✅ `testRemoveFromBlocklistBatch_Success()` - Batch blocklist removal
- ✅ `testRemoveFromBlocklistBatch_RevertOn_ZeroAddress()` - Zero address validation
- ✅ `testRemoveFromBlocklistBatch_Revert_InvalidCall()` - Unauthorized access prevention
- ✅ `test_RemoveFromBlocklistBatch_RevertWhen_AlreadyUnBlocklisted()` - Duplicate prevention

#### 5. **Transfer Restrictions** (8 tests)

- ✅ `test_Transfer_RevertIf_SenderBlocklisted()` - Blocked sender prevention
- ✅ `test_Transfer_RevertIf_RecipientBlocklisted()` - Blocked recipient prevention
- ✅ `test_Approve_RevertIf_OwnerBlocklisted()` - Blocked owner approval prevention
- ✅ `test_Approve_RevertIf_SpenderBlocklisted()` - Blocked spender approval prevention
- ✅ `test_TransferFrom_RevertIf_SenderBlocklisted()` - Blocked sender transferFrom prevention
- ✅ `test_TransferFrom_RevertIf_RecipientBlocklisted()` - Blocked recipient transferFrom prevention
- ✅ `test_Transfer_RevertIf_Paused()` - Paused state transfer prevention
- ✅ `test_Approve_RevertIf_Paused()` - Paused state approval prevention

#### 6. **Upgrade & Edge Cases** (2 tests)

- ✅ `test_Upgrade_AccessControl()` - Upgrade authorization verification
- ✅ `test_Transfer_RevertIf_ZeroAmount()` - Zero amount transfer prevention

### 🔧 Test Execution

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test category
forge test --match-test "test_pause"

# Run with detailed output
forge test -vvv
```

## Test Coverage

[![codecov](https://codecov.io/gh/jayp11/neba-token/branch/main/graph/badge.svg?token=YOUR_CODECOV_TOKEN)](https://codecov.io/gh/jayp11/neba-token)

For full coverage details, see [audits/coverage.md](./audits/coverage.md)

## 🔧 Configuration

### Foundry Configuration

The project uses Foundry for development and testing. Key configuration in `foundry.toml`:

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
```

### Dependencies

Contracts use ^0.8.20 to remain forward-compatible with future compiler releases.

- **OpenZeppelin Contracts**: v5.0+ (upgradeable versions)
- **Forge Standard Library**: For testing utilities

## 🛡️ Security Considerations

### Upgrade Safety

- Uses UUPS pattern for safe upgrades
- Only UPGRADER_ROLE can authorize upgrades
- Storage gap prevents storage collisions

### Access Control

- Role-based permissions prevent unauthorized access
- Separate roles for different administrative functions
- Bot role limited to pause functionality only

### Compliance Features

- Blocklist for regulatory compliance
- Pause functionality for emergency situations
- Audit trail through events

## 📊 Token Economics

- **Name**: NEBA Token
- **Symbol**: NEBA
- **Decimals**: 18
- **Total Supply**: 1,000,000,000 NEBA
- **Supply Type**: Fixed (no minting after deployment)

## 🔄 Upgrade Process

1. Deploy new implementation contract
2. Call `upgradeToAndCall()` with new implementation address
3. Only UPGRADER_ROLE can authorize upgrades
4. Storage layout must be compatible

## 📝 Events

```solidity
event AddressBlocklisted(address indexed account, uint256 timestamp);
event AddressUnblocklisted(address indexed account, uint256 timestamp);
event CircuitBreakerActivated(address indexed by, uint256 timestamp);
event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);
```
