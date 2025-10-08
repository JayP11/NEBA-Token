# 🧭 NEBA Token — Keeper Bot Emergency Pause Drill

[Network]: Base Sepolia
[Contract]: NEBAToken
[Proxy]: 0x0092296419183b5B375114f75Fe3B08ce94Af1D3
[BOT_PAUSER_ROLE]: 0xdb48f8cfDd9DB6f417d0FEEacFb57F0cb036a599
[ADMIN_PAUSER_ROLE]: 0xC77eDD9A5A23Db71220b185Ed7Be63CC02cA05dD
[RPC]: https://sepolia.base.org

🧪 Objective

Demonstrate that:

- A keeper bot (BOT_PAUSER_ROLE) can trigger pause() in response to off-chain alerts.
- Governance (ADMIN_PAUSER_ROLE) can safely unpause to recover.
- Both steps are verifiable on-chain.
- This serves as operational evidence for auditors.

# 📝 Prerequisites

### .env file with the following:

BOT_KEY=<private_key_of_bot_pauser>
ADMIN_PAUSER_KEY=<private_key_of_admin_pauser>

### Base Sepolia RPC access

### cast installed (via Foundry)

#

## 1️⃣ Fund Keeper Bot

cast send 0x732DaD9144E795475328d5aF9A14a0a233c48894 \
 --value 0.01ether \
 --to 0xdb48f8cfDd9DB6f417d0FEEacFb57F0cb036a599 \
 --rpc-url https://sepolia.base.org \
 --private-key $ADMIN_TREASURY_KEY

✅ Ensures keeper has gas to call pause().

## 2️⃣ Keeper Calls pause()

### Calldata for pause():

cast calldata "pause()"
0x8456cb59

### Execute:

cast send 0x0092296419183b5B375114f75Fe3B08ce94Af1D3 \
 "pause()" \
 --rpc-url https://sepolia.base.org \
 --private-key $BOT_KEY

👉 Expected: CircuitBreakerActivated event emitted.
👉 Tx Hash: https://sepolia.basescan.org/tx/0x5f2c375f5f5ceee6c58995d416c4daff4275f0f42407acb0ee31cdfc560cda21

### Verify paused state:

cast call 0x0092296419183b5B375114f75Fe3B08ce94Af1D3 "paused()" --rpc-url https://sepolia.base.org

3️⃣ Admin Pauser Unpauses
cast send 0x0092296419183b5B375114f75Fe3B08ce94Af1D3 \
 "unpause()" \
 --rpc-url https://sepolia.base.org \
 --private-key $ADMIN_PAUSER_KEY
👉 Expected: CircuitBreakerDeactivated event emitted.
👉 Tx Hash: https://sepolia.basescan.org/tx/0x8ec4de735c605b4bdc6e50095f729a5a68c0ba5300c5284ca195df2c3fb152bd

### Verify unpaused state:

cast call 0x0092296419183b5B375114f75Fe3B08ce94Af1D3 "paused()" --rpc-url https://sepolia.base.org

✅ Outcome

This drill provides on-chain proof that:
Off-chain monitoring / keeper bot can pause the protocol in emergencies.
Governance can unpause safely, restoring operations.

The system is operationally ready for production.
