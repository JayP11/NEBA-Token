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

### Roles

| Role               | Can Do                 |
| ------------------ | ---------------------- |
| **Admin Treasury** | Grant roles and Revoke |
| **Admin Pauser**   | Pause & UnPause        |
| **Bot Pauser**     | Pause only             |
| **Upgrader**       | Upgrade contract       |

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
    adminPauser,      // Address that can pause and unpause
    botAddress        // Address for automated keeper bot
);

ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
NEBAToken nebaToken = NEBAToken(address(proxy));
```

## LOC

```
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Solidity                         1             17             57             75
-------------------------------------------------------------------------------
```

### Test Coverage

```
╭------------------------------------------+------------------+------------------+-----------------+-----------------╮
| File                                     | % Lines          | % Statements     | % Branches      | % Funcs         |
+====================================================================================================================+
| contracts/NEBAToken.sol                  | 100.00% (31/31)  | 100.00% (29/29)  | 100.00% (5/5)   | 100.00% (8/8)   |
|------------------------------------------+------------------+------------------+-----------------+-----------------|
| test/NEBAToken.integration.t.sol         | 100.00% (4/4)    | 100.00% (2/2)    | 100.00% (0/0)   | 100.00% (2/2)   |
|------------------------------------------+------------------+------------------+-----------------+-----------------|
| test/invariants/NEBATokenInvariant.t.sol | 98.63% (72/73)   | 98.63% (72/73)   | 100.00% (8/8)   | 100.00% (10/10) |
|------------------------------------------+------------------+------------------+-----------------+-----------------|
| Total                                    | 99.07% (107/108) | 99.04% (103/104) | 100.00% (13/13) | 100.00% (20/20) |
╰------------------------------------------+------------------+------------------+-----------------+-----------------╯
NOTE: Fuzz tests (test/NEBAToken.fuzz.t.sol) are not included in the above coverage table by default. They are used to explore edge cases and invariants beyond fixed test cases.
```

[![codecov](https://codecov.io/gh/JayP11/NEBA-Token/graph/badge.svg?token=1RBCTQAIS2)](https://codecov.io/gh/JayP11/NEBA-Token)

For full coverage details, see [audits/coverage.md](./audits/coverage.md)

## 📊 Test Coverage Summary

The NEBA Token contract has comprehensive test coverage with **70 test cases** covering all critical functionality.

### 📈 Coverage Statistics

- **Total Tests**: 70
- **Pass Rate**: 100% (70/70 passed)

## 🧮 Audit Factsheet

| Item              | Value                                    |
| ----------------- | ---------------------------------------- |
| Solidity Pragma   | 0.8.30                                   |
| Solidity Compiler | 0.8.30(pinned in foundry.toml)           |
| Optimizer Runs    | 200                                      |
| Networks          | Base Mainnet, Base Sepolia               |
| Chain IDs         | 8453 (Mainnet), 84532 (Sepolia)          |
| Third-party Deps  | OpenZeppelin v5 (Upgradeable), Forge Std |
| Total LOC         | 71 (Solidity)                            |

### Files Architecture

├── 📁 audits/ # Security & audit artifacts
│ ├── [NEBAToken](audits/addresses.json) # Deployed contract addresses per network
│ ├── [NEBAToken](audits/coverage.md) # Detailed coverage summary
│ ├── [NEBAToken](audits/RUNBOOK.md) # Operational runbook for incident response
│ ├── [NEBAToken](audits/emergencyRunbook.md) # Emergency runbook for incident response
│ ├── [NEBAToken](audits/slither.md) # Static analysis summary (Slither)
│ ├── [NEBAToken](audits/slitherResults.json) # Full JSON output from Slither analysis
│ └── [NEBAToken](audits/threat-model.md) # Threat modeling & security assumptions
|
├── 📁 contracts/ # Core smart contracts
│ └── [NEBAToken](contracts/NEBAToken.sol) # Upgradeable ERC-20 implementation
|
├── 📁 docs/ # Generated contract [NatSpec] documentation
│ └── [NEBAToken](docs/src/contracts/NEBAToken.sol/NEBAToken.md)
| └── [NEBAToken](docs/DEPLOYMENT.md) # DEPLOYMENT & VERIFICATION
|
├── 📁 script/ # Deployment & utility scripts
│ └── [NEBAToken](script/NEBAToken.s.sol) # Foundry script for deploying the token
|
├── 📁 test/ # Full test suite (Foundry)
│ ├── invariants/ # Invariant & stateful fuzz tests
│ │ └── [NEBAToken](test/invariants/NEBATokenInvariant.t.sol)
│ ├── [NEBAToken](test/ForkCheck.t.sol) # Fork verification test
│ ├── [NEBAToken](test/NEBAToken.integration.t.sol) # Integration tests
│ ├── [NEBAToken](test/NEBAToken.t.sol) # Core unit tests
│ └── [NEBAToken](test/NEBATokenFuzzTest.t.sol) # Fuzz tests for edge cases
│
├── 📁 tools/ # Dev & analysis tooling
│ ├── [NEBAToken](tools/.gas-snapshot) # Gas report snapshot (for`forge snapshot`)
│ ├── [NEBAToken](tools/slither.config.json) # Slither analysis configuration
│ └── [NEBAToken](tools/storage-layout-v1.md) # Storage layout snapshot for upgrade safety
│
├── 📄 [NEBAToken](./foundry.toml) # Foundry configuration (compiler, optimizer, network)
├── 📄 [NEBAToken](./README.md) # Project documentation
├── 📄 [NEBAToken](./lcov.info) # Coverage report (for Codecov)
├── 📄 [NEBAToken](./broadcast/NEBAToken.s.sol) # Broadcast

### 🧰 Commands

```bash
forge build           # Compile contracts
forge test            # Run tests
forge script ...      # Deploy
forge coverage
```

## 📚 Documentation

Full contract documentation is available in the [docs](./docs/src/contracts/NEBAToken.sol/contract.NEBAToken.md) directory, generated from [NatSpec] comments.

### View Documentation

**Local viewing:**

```bash
forge doc --serve
```

## 🔧 Configuration

### Foundry Configuration

The project uses Foundry for development and testing. Key configuration in `foundry.toml`:

#### Optimizer Configuration

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc_version = "0.8.30"


optimizer = true
optimizer_runs = 200

via_ir = true

[profile.default.invariant]
runs = 256
depth = 15
fail_on_revert = false
call_override = false
```

### External Dependencies

Contracts use 0.8.30

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

```

```
