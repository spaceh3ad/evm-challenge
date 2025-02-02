# Architecture & Design

![](./img/architecture.png)

# Table of Contents

1. [Architecture Design Decisions](#1-architecture-design-decisions)
   - [Clone Factory Pattern](#clone-factory-pattern)
   - [Upgradeability Strategy](#upgradeability-strategy)
   - [Liquidity Bootstraping](#liquidity-bootstrapping)
   - [State Management](#state-management)
2. [Contract Architecture](#2-contract-architecture)
   - [2.1 Factory Contract](#21-factory-contract)
     - [Submission Creation](#submission-creation)
     - [Upgrade Process](#upgrade-process)
   - [2.2 Curation Contract](#22-curation-contract)
     - [State Transitions](#state-transitions)
3. [Data Flow](#3-data-flow)
   - [3.1 Token Submission](#31-token-submission)
   - [3.2 Staking & Pool Creation](#32-staking--pool-creation)
4. [User Guide](#4-user-guide)
   - [4.1. Create Submission](#41-create-submission)
   - [4.2. Staking Tokens](#42-staking-tokens)
   - [4.3. Unstake Tokens](#43-unstake-tokens)
   - [4.4. Claiming Rewards](#44-claiming-rewards)
   - [4.5. Curation Upgrade](#45-curation-upgrade)
   - [4.6. Factory Upgrade](#46-factory-upgrade)

## 1. Architecture Design Decisions

### **Clone Factory Pattern**

- Reduces deployment costs via proxy clones.
- Uses ERC-1167 minimal proxies for gas-efficient deployment.
- Enables mass creation of curation contracts with shared logic via clones pattern.
- Implementation upgrades affect only new deployments.

### **Upgradeability Strategy**

- Transparent Upgradability Proxy for Factory updates.
- Owner-controlled implementation upgrades.
- Allows changing implementation contract for Curation.
- Factory stores and updates curation implementation.

### **Liquidity Bootstrapping**

- Automated Uniswap V3 pool creation once sufficient tokens are staked.
- Full-range liquidity positions for maximum exposure.
- Price determined by tokens ratio.

### **State Management**

- Two-stage lifecycle (Pending → Ended).
- Staked amounts tracking with mapping optimizations.
- Token balances verified through SafeERC20.

## 2. Contract Architecture

### 2.1 Factory Contract

```
contract Factory {
    // Core dependencies
    address public curationImplementation;
    address public positionManager;

    // Curation registry
    address[] public curations;

    // Lifecycle
    function createSubmission(CurationDetails) → clone;
    function upgradeImplementation(address);

    // View
    function getCurationsData() → FullCurationInfo[];
}
```

### Submission Creation

```
User → createSubmission()
     ↓
Parameter Validation → Clone Creation → Token Transfer → Initialization
     ↓
Curation Added to Registry
```

### Upgrade Process

```
Admin → upgradeImplementation()
     ↓
Factory updates stored curation logic
     ↓
New Curation Contracts use updated logic
```

### 2.2 Curation Contract

```
contract Curation {
    // Configuration
    CurationDetails public curationDetails;
    address public positionManager;

    // State
    CurationStatus public curationStatus;
    mapping(address → uint256) public stakedAmounts;

    // Lifecycle
    function initialize();
    function stake(uint256);
    function unstake(uint256);
    function claim();

    // Internal
    function _setUpPool();
}
```

### State Transitions

```
         initialize()
            ↓
[PENDING] → stake() → [ENDED]
  ↓    ↖      ↓
unstake()    claim()
```

## 3. Data Flow

### 3.1 Token Submission

![](./img/tokenSubmission.png)

### 3.2 Staking & Pool Creation

![](./img/stake.png)

## 4. User Guide

### 4.1. Create Submission

```
// prepare curationDetails object
const curationDetails = {
  newToken: "0x...", // ERC20 address
  curationToken: "0x...", // Staking token
  distributionAmount: 500000, // Tokens for distribution
  targetAmount: 100000, // Staking target
  liquidityAmount: 200000, // Liquidity pool tokens
  creator: "0x...", // Your address
};

// approve token transfer
newToken.approve(factory.address, totalAmount);

// create curation
factory.createSubmission(curationDetails);
```

### 4.2. Staking Tokens

Requirements:

- curation status == PENDING

```
// approve curationTokens to new instance
curationToken.approve(curationAddress, amount);

// invoke stake function on instance
curationContract.stake(amount);
```

### 4.3. Unstake Tokens

Requirements:

- curation status == PENDING
- user has stake

```
// invoke unstake function on instance
curationContract.unstake(amount);
```

### 4.4. Claiming Rewards

Requirements:

- curation status == ENDED
- user has positive stake

```
// invoke claim function on instance
curationContract.claim();
// claim amount = (stakedAmount / targetAmount) * distributionAmount
```

### 4.5. Curation Upgrade

Requirements:

- invoked from privileged account
- deployed new version of curation

```
factory.upgradeImplementation(_newImplementation);
```

### 4.6. Factory Upgrade

Requirements:

- invoked from privileged account

```
factory.upgradeFactory(_newImplementation);
```
