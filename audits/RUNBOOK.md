# 🧭 NEBA Token — Operational Runbook

**Contract:** NEBAToken  
**Network:** Base Mainnet  
**Proxy Pattern:** UUPS  
**Tools:** Foundry

---

## 🧑‍💼 Role Setup & Assignment

```
| Role                 | Purpose                     | Assigned To       |
| -------------------- | --------------------------- | ----------------- |
| `DEFAULT_ADMIN_ROLE` | Grant/revoke roles          | `adminTreasury`   |
| `ADMIN_PAUSER_ROLE`  | Pause & unpause token       | `adminPauser`     |
| `BOT_PAUSER_ROLE`    | Bot can pause (not unpause) | `botAddress`      |
| `UPGRADER_ROLE`      | Authorize upgrades          | `upgraderAddress` |
```

**Verification Command (Foundry):**

```bash
cast call <proxy> "hasRole(bytes32,address)" <ROLE_HASH> <ADDRESS>
```

## Emergency Pause / Unpause

### Pause Token Transfers

```bash
cast send <proxy> "pause()" --private-key <PAUSER_KEY>
```

### Unpause Token Transfers

```bash
cast send <proxy> "unpause()" --private-key <ADMIN_PAUSER_KEY>
```

# ⬆️ Upgrade Procedure

1. Deploy new implementation

```bash
forge create --private-key <DEPLOYER_KEY> src/NEBATokenV2.sol:NEBATokenV2
```

2. Upgrade via proxy (UPGRADER_ROLE)

```bash
cast send <proxy> "upgradeTo(address)" <new_impl> --private-key <UPGRADER_KEY>
```

3. Verify upgrade

```bash
cast call <proxy> "implementation()"
```

# 🛠 Incident Playbooks

```
| Incident                | Action                                                      |
| ----------------------- | ----------------------------------------------------------- |
| Contract bug / exploit  | Pause immediately → Notify team → Investigate               |
| Upgrader key compromise | Revoke role → Assign new secure upgrader                    |
| Admin key compromise    | Pause (if possible) → Rotate roles → Use secure multisig    |
| Stuck in paused state   | Only `ADMIN_PAUSER_ROLE` can unpause → Use secure admin key |
```

# 🧰 Useful Commands

## Check role:

```bash
cast call <proxy> "hasRole(bytes32,address)" <ROLE> <ADDRESS>
```

## Pause / Unpause:

### (ADMIN_PAUSER_ROLE or BOT_PAUSER_ROLE)

```bash
cast send <proxy> "pause()" --private-key <KEY>
```

### (Only ADMIN_PAUSER_ROLE)

```bash
cast send <proxy> "unpause()" --private-key <KEY>
```

## Upgrade:

```bash
cast send <proxy> "upgradeTo(address)" <impl> --private-key <UPGRADER_KEY>
```

# 📝 Deployment Summary

- Implementation: Deployed separately (see deployment logs / Etherscan)
- Proxy (Main): Use this for all interactions
- Supply: Fixed, minted to adminTreasury at initialization
