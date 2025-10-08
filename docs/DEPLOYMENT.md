# 🚀 Deployment and On-Chain Verification

Network: Base Sepolia
Proxy Pattern: UUPS
Deployer: 0x732DaD9144E795475328d5aF9A14a0a233c48894
Implementation: 0x5EE297aE69332af86E8A243bDb3E7C94bd6f2866
Proxy (Token): 0x0092296419183b5B375114f75Fe3B08ce94Af1D3
Admin / UUPS Upgrader: 0x03b4Ec4B9bebAb94577C686cC46D45128e281c3C

---

# 📜 Deployment Command

```base
source .env
forge script script/NEBAToken.s.sol:DeployNEBAToken \
  --rpc-url base_sepolia \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
```

# 🧾 Terminal Output (Deployment)

Deployer: 0x732DaD9144E795475328d5aF9A14a0a233c48894
Implementation deployed at: 0x5EE297aE69332af86E8A243bDb3E7C94bd6f2866
Proxy deployed at: 0x0092296419183b5B375114f75Fe3B08ce94Af1D3
Token name: NEBA Token
Token symbol: NEBA
Total supply: 1,000,000,000,000,000,000,000,000,000 (1e27)
...
✅ [Success] Hash (Implementation): 0x5feab18c9a71b826bc1ae90676fa0893b9010b1b574c76011f1b78042171b639
✅ [Success] Hash (Proxy): 0x21c67f7344fd7c61c24c9532e972beadf73c05c124e16726421cfa947d97a1ad

# 🔍 Verification

```base
forge verify-contract \
  0x5EE297aE69332af86E8A243bDb3E7C94bd6f2866 \
  contracts/NEBAToken.sol:NEBAToken \
  --chain base-sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY

forge verify-contract \
  0x0092296419183b5B375114f75Fe3B08ce94Af1D3 \
  contracts/NEBAToken.sol:NEBAToken \
  --chain base-sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY


```

# Terminal Output:

Response: OK
GUID: 2ubj64rdwqrggx9zepex3gibvivmtyshiv2vy2dk1m7rkrjdvr
URL: https://sepolia.basescan.org/address/0x5EE297aE69332af86E8A243bDb3E7C94bd6f2866#code

Response: `OK`
GUID: `p6bbwjn3a4f6gw3azzq7y3cpe9chv1zmkwvmsajikymijnk9hc`
URL: https://sepolia.basescan.org/address/0x0092296419183b5b375114f75fe3b08ce94af1d3
