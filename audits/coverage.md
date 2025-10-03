# NEBAToken.sol Coverage Report

- **Overall Coverage**: 96%+ statements and branches (as reported by Codecov)
- **Coverage Badge**: [![codecov](https://codecov.io/gh/jayp11/neba-token/branch/main/graph/badge.svg?token=YOUR_CODECOV_TOKEN)](https://codecov.io/gh/jayp11/neba-token)

## NEBAToken.sol Coverage

| Function / Section       | Lines Covered | Total Lines | Notes                             |
| ------------------------ | ------------- | ----------- | --------------------------------- |
| constructor              | 32            | 32          | Fully covered                     |
| onlyPausers              | 11            | 11          | Fully covered                     |
| initialize               | 32            | 32          | Fully covered                     |
| pause                    | 11            | 11          | Fully covered                     |
| unpause                  | 5             | 5           | Fully covered                     |
| \_authorizeUpgrade       | 2             | 2           | Fully covered                     |
| addToBlocklistBatch      | 14            | 14          | Fully covered                     |
| removeFromBlocklistBatch | 6             | 6           | Fully covered                     |
| isBlocklisted            | 4             | 4           | Fully covered                     |
| \_update                 | 39            | 39          | Fully covered                     |
| nonces (getter)          | 0             | 0           | Low risk, no tests required       |
| \_approve                | 7             | 7           | Some edge branches may be missing |

## Negative Tests

- Reverts on unauthorized access
- Reverts on paused states
- Boundary checks for zero/empty inputs
- Access control failures tested

## Integration Tests

- Full flow tested: ERC20 operations, blocklist updates
- Upgrade path tested with `_authorizeUpgrade` and proxy
- Interactions between pause/unpause and transfers tested
