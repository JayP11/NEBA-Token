# NEBA Token - Threat Model

## Assets at Risk

- 1B NEBA tokens (adminTreasury)
- All user balances
- Contract upgrade control
- Role access keys

## Critical Threats

**1. Admin Key Compromise** → Full control, can dump tokens, pause forever  
**Fix**: 3-of-5 multi-sig

**2. Malicious Upgrade** → Instant fund theft, no timelock  
**Fix**: 48hr timelock + separate multi-sig

**3. Initialize Front-Run** → Attacker becomes admin first  
**Fix**: Initialize in deployment transaction

**4. Bot DoS** → Repeated pausing halts transfers  
**Fix**: 24hr cooldown, 7-day max pause

**5. Lost Keys + Paused** → Funds locked forever  
**Fix**: Auto-unpause or guardian recovery

## Trust Assumptions

- **adminTreasury**: Won't go rogue (has DEFAULT_ADMIN + PAUSER roles)
- **upgraderAddress**: Only deploys safe code
- **botAddress**: Only pauses for real emergencies
- **OpenZeppelin**: No vulnerabilities

## Emergency Procedures

**Suspicious Activity**  
Bot pauses → Investigate → Upgrade if needed → Unpause

**Admin Compromised**  
Pause → Emergency upgrade to revoke old admin → Verify → Communicate

**Malicious Upgrade**  
If caught: Front-run with safe version  
If deployed: Migration to new contract likely needed

**Bot Compromised**  
Admin unpause → Revoke bot role → Deploy new bot

## Must-Do Before Launch

- [ ] Multi-sig wallets (3-of-5+ for admin, 4-of-7 for upgrader)
- [ ] Upgrade timelock (48hr)
- [ ] Secure initialization
- [ ] Security audit
- [ ] 24/7 monitoring setup

## Risk Priority

1. **P0**: Admin key, Malicious upgrade, Initialize front-run
2. **P1**: Bot DoS, Lost keys while paused
