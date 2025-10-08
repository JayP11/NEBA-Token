# NEBA Token

A secure, upgradeable ERC-20 token implementation with strong security primitives, emergency controls, and upgradeable architecture designed for future governance features, built on OpenZeppelin's battle-tested contracts.

## 🌟 Overview

NEBA Token is a production-ready ERC-20 token with a fixed supply of 1 billion tokens (1,000,000,000 NEBA with 18 decimals). The contract is designed with enterprise-grade security features, compliance tools, and future governance capabilities.

## ✨ Key Features

### 🔒 Security & Compliance

- **UUPS Upgradeable**: Safe contract upgrades with proper authorization
- **Role-Based Access Control**: Granular permissions for different administrative functions
- **Pausable Transfers**: Emergency pause functionality for crisis management
- **Reentrancy Protection**: Built-in guards against reentrancy attacks

### 🛡️ Advanced Features

- **Custom Errors**: Gas-efficient error handling
- **Storage Gap**: Safe upgrade pattern with reserved storage slots
- **Comprehensive Testing**: Full test coverage with Foundry

## 🏗️ Architecture

### Contract Structure

```
NEBAToken
├── ERC20Upgradeable (Base token functionality)
├── ERC20PausableUpgradeable (Pause/unpause transfers)
├── AccessControlUpgradeable (Role management)
├── UUPSUpgradeable (Safe upgrades)
└── ReentrancyGuardUpgradeable (Reentrancy protection)
```

### Role System

- **DEFAULT_ADMIN_ROLE**: Full administrative control
- **ADMIN_PAUSER_ROLE**: Can pause/unpause transfers
- **BOT_PAUSER_ROLE**: Can pause transfers, but cannot unpause (for automated systems)
- **UPGRADER_ROLE**: Can upgrade contract implementation

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

# Install OpenZeppelin and Forge std lib
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@5.0.2
forge install foundry-rs/forge-std

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

## solc_version = 0.8.20

## LOC

````-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Solidity                         1             17             57             75
-------------------------------------------------------------------------------```
````

### Test Coverage

```
╭----------------------------------+-----------------+-----------------+---------------+----------------╮
| File                             | % Lines         | % Statements    | % Branches    | % Funcs        |
+=======================================================================================================+
| contracts/NEBAToken.sol          | 100.00% (30/30) | 100.00% (27/27) | 100.00% (4/4) | 100.00% (8/8)  |
|----------------------------------+-----------------+-----------------+---------------+----------------|
| test/NEBAToken.integration.t.sol | 100.00% (4/4)   | 100.00% (2/2)   | 100.00% (0/0) | 100.00% (2/2)  |
|----------------------------------+-----------------+-----------------+---------------+----------------|
| Total                            | 100.00% (34/34)  | 100.00% (29/29)| 100.00% (4/4) | 100.00%(10/10) |
╰----------------------------------+-----------------+-----------------+---------------+----------------╯
NOTE: Fuzz tests (test/NEBAToken.fuzz.t.sol) are not included in the above coverage table by default. They are used to explore edge cases and invariants beyond fixed test cases.
```

## 📊 Test Coverage Summary

The NEBA Token contract has comprehensive test coverage with **41 test cases** covering all critical functionality:

### 📈 Coverage Statistics

- **Total Tests**: 41
- **Pass Rate**: 100% (41/41 passed)

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

[![codecov](https://codecov.io/gh/JayP11/NEBA-Token/graph/badge.svg?token=1RBCTQAIS2)](https://codecov.io/gh/JayP11/NEBA-Token)

For full coverage details, see [audits/coverage.md](./audits/coverage.md)

## 📚 Documentation

Full contract documentation is available in the [docs](./docs/src/contracts/NEBAToken.sol/contract.NEBAToken.md) directory, generated from NatSpec comments.

### View Documentation

**Local viewing:**

````bash
forge doc --serve


## 🔧 Configuration

### Foundry Configuration

The project uses Foundry for development and testing. Key configuration in `foundry.toml`:

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
````

### External Dependencies

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
event CircuitBreakerActivated(address indexed by, uint256 timestamp);
event CircuitBreakerDeactivated(address indexed by, uint256 timestamp);
```

## 📄 License

This project is licensed under the [MIT License](./LICENSE).
