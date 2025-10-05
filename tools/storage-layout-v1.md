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
