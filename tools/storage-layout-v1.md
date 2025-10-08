## Current Status

Since NEBATokenV2 hasn't been created yet, this document shows:

## V1 Baseline - Current storage layout

Command Run:
forge inspect NEBAToken storageLayout

```
╭-------+-------------+------+--------+-------+-----------------------------------╮
| Name  | Type        | Slot | Offset | Bytes | Contract                          |
+=================================================================================+
| __gap | uint256[50] | 0    | 0      | 1600  | contracts/NEBAToken.sol:NEBAToken |
╰-------+-------------+------+--------+-------+-----------------------------------╯
```

## Full Storage Layout (Including Inherited):

Slot 0: \_initialized (uint8) + \_initializing (bool) [Initializable]
Slot 1: \_balances (mapping) [ERC20Upgradeable]
Slot 2: \_allowances (mapping) [ERC20Upgradeable]
Slot 3: \_totalSupply (uint256) [ERC20Upgradeable]
Slot 4: \_name (string) [ERC20Upgradeable]
Slot 5: \_symbol (string) [ERC20Upgradeable]
Slot 6: \_paused (bool) [PausableUpgradeable]
Slot 7: \_roles (mapping) [AccessControlUpgradeable]
Slot 8-57: \_\_gap[50] (uint256[50]) [NEBAToken]

Total Slots Used: 58 slots

###

- Inherited slots (0-7) are unchanged
- New variables start at slot 8+
- Gap size reduced by number of new variables
- Total slots remain within original bounds

### Test Logs

```base forge test --match-test test_StorageGap_PreventsFutureStorageCollisions -vvvv ````

apple@apples-MacBook-Pro NEBA-Token % forge test --match-test test_StorageGap_PreventsFutureStorageCollisions -vvvv

[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for test/NEBATOKEN.t.sol:NEBATokenTest
[PASS] test_StorageGap_PreventsFutureStorageCollisions() (gas: 1626284)
Traces:
[1626284] NEBATokenTest::test_StorageGap_PreventsFutureStorageCollisions()
├─ [0] VM::prank(adminTreasury: [0xDf773E36AFCcEFe03688aFC5CEd8a3b9534c01d0])
│ └─ ← [Return]
├─ [37169] ERC1967Proxy::fallback(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 5000000000000000000000 [5e21])
│ ├─ [32356] NEBAToken::transfer(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], 5000000000000000000000 [5e21]) [delegatecall]
│ │ ├─ emit Transfer(from: adminTreasury: [0xDf773E36AFCcEFe03688aFC5CEd8a3b9534c01d0], to: user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF], value: 5000000000000000000000 [5e21])
│ │ └─ ← [Return] true
│ └─ ← [Return] true
├─ [1097] ERC1967Proxy::fallback(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]) [staticcall]
│ ├─ [787] NEBAToken::balanceOf(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]) [delegatecall]
│ │ └─ ← [Return] 5000000000000000000000 [5e21]
│ └─ ← [Return] 5000000000000000000000 [5e21]
├─ [2651] ERC1967Proxy::fallback() [staticcall]
│ ├─ [2344] NEBAToken::totalSupply() [delegatecall]
│ │ └─ ← [Return] 1000000000000000000000000000 [1e27]
│ └─ ← [Return] 1000000000000000000000000000 [1e27]
├─ [3223] ERC1967Proxy::fallback(0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3, upgraderAddress: [0xd473a8f2879EA71d931189000a54368e07407e68]) [staticcall]
│ ├─ [2910] NEBAToken::hasRole(0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3, upgraderAddress: [0xd473a8f2879EA71d931189000a54368e07407e68]) [delegatecall]
│ │ └─ ← [Return] true
│ └─ ← [Return] true
├─ [1490121] → new NEBATokenV2@0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
│ ├─ emit Initialized(version: 18446744073709551615 [1.844e19])
│ └─ ← [Return] 7326 bytes of code
├─ [0] VM::prank(upgraderAddress: [0xd473a8f2879EA71d931189000a54368e07407e68])
│ └─ ← [Return]
├─ [6940] ERC1967Proxy::fallback(NEBATokenV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x)
│ ├─ [6624] NEBAToken::upgradeToAndCall(NEBATokenV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x) [delegatecall]
│ │ ├─ [551] NEBATokenV2::proxiableUUID() [staticcall]
│ │ │ └─ ← [Return] 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
│ │ ├─ emit Upgraded(implementation: NEBATokenV2: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a])
│ │ └─ ← [Stop]
│ └─ ← [Return]
├─ [0] VM::prank(adminTreasury: [0xDf773E36AFCcEFe03688aFC5CEd8a3b9534c01d0])
│ └─ ← [Return]
├─ [24848] ERC1967Proxy::fallback(99999 [9.999e4])
│ ├─ [24541] NEBATokenV2::setNewFeature(99999 [9.999e4]) [delegatecall]
│ │ └─ ← [Stop]
│ └─ ← [Return]
├─ [1119] ERC1967Proxy::fallback(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]) [staticcall]
│ ├─ [809] NEBATokenV2::balanceOf(user1: [0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF]) [delegatecall]
│ │ └─ ← [Return] 5000000000000000000000 [5e21]
│ └─ ← [Return] 5000000000000000000000 [5e21]
├─ [651] ERC1967Proxy::fallback() [staticcall]
│ ├─ [344] NEBATokenV2::totalSupply() [delegatecall]
│ │ └─ ← [Return] 1000000000000000000000000000 [1e27]
│ └─ ← [Return] 1000000000000000000000000000 [1e27]
├─ [1245] ERC1967Proxy::fallback(0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3, upgraderAddress: [0xd473a8f2879EA71d931189000a54368e07407e68]) [staticcall]
│ ├─ [932] NEBATokenV2::hasRole(0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3, upgraderAddress: [0xd473a8f2879EA71d931189000a54368e07407e68]) [delegatecall]
│ │ └─ ← [Return] true
│ └─ ← [Return] true
├─ [1113] ERC1967Proxy::fallback() [staticcall]
│ ├─ [806] NEBATokenV2::newFeatureValue() [delegatecall]
│ │ └─ ← [Return] 99999 [9.999e4]
│ └─ ← [Return] 99999 [9.999e4]
└─ ← [Return]

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 3.79ms (971.01µs CPU time)

Ran 1 test suite in 447.26ms (3.79ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
