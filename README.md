# ☕ moka-contract

📜 **moka-contract** is a smart contract designed to **record, trace, and store verifiable proofs of transactions between users**.  
It also tracks and logs **the status and every action** taken on each transaction, ensuring **full transparency and traceability**.

---

## ✨ Features

- ✅ Register a transaction with a unique identifier
- 📜 Keep an immutable proof on-chain
- 🏷️ Manage and update the status of each transaction (e.g., pending, confirmed, canceled)
- 📊 Track the complete history of actions performed on transactions
- 🔐 Secure and transparent thanks to blockchain

---

## ⚙️ Technology

- 🌌 **StarkNet**: Layer 2 blockchain leveraging zk-STARKs
- ✍ **Cairo**: Smart contract programming language
- 📦 Managed with **Scarb** and **Starknet CLI**

---

## 🚀 Getting started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/moka-contract.git
cd moka-contract
```

### 2. Install dependencies

```bash
scarb build
```

### 3. Deploy the contract

```bash
starknet deploy --contract MokaContract --network devnet
```

### 4. Interact with the contract

```bash
starknet call --contract <contract_address> --function <function_name> --network devnet
```
