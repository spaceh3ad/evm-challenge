# Token Launch Curation Challenge (Updated)

## Overview

The goal is to build a **smart contract system** that enables **community-driven curation** of new token launches (**New Token**) using an **existing ERC20 token (CurationToken)** as the curation mechanism. Create a system where **curators stake tokens** to vote on the **legitimacy** of new token launches. Curators stake the **CurationToken** to signal their interest in the **New Token**.



## Core Requirements

### 1. Token Launch Submission

Curators must evaluate and vote on submitted token launches. Submissions should include:

1. **Token Address**: The contract address of the submitted token.  
2. **Amount of New Token To be Distributed**: The amount of **New Tokens** that will be distributed if the curation is successful.  
3. **Target Amount of CurationTokens**: The amount of **CurationTokens** needed to have a successful curation.

### 2. Curation Mechanism

#### Stake Tokens
- Participants must stake **CurationToken** (an existing ERC20 token) to curate token launches.

#### Unstake Tokens
- Participants can unstake their **CurationTokens** after a certain amount of time.

#### Successful Curation
- If enough tokens are staked, the curation is considered a success.
- The **CurationTokens** are **burnt**, and participants can claim their share of **New Tokens**.

### 3. Deliverables

1. **Smart Contract Code**  
   - Staking mechanism  
   - Unstaking mechanism  
   - Claiming mechanism  
   - Security best practices  

2. **Documentation**  
   - Technical documentation of the system explaining design choices  
   - User guide for curators and token submitters  



## Optional / Advanced Requirements

Below are additional features that can be implemented to **enhance** or **extend** the curation system. They are **not mandatory** but will showcase advanced expertise.

### A. Factory Contract

- **Objective**: Instead of deploying a single curation contract, create a **factory contract** that can deploy new instances of the curation contract for each token launch proposal.

- **Key Points**:
  1. **Isolated Instances**: Each curation contract instance is independent, reducing cross-contamination of risks.
  2. **Registry**: The factory can maintain a registry or emit events so users can discover active curation instances.
  3. **Ownership / Governance**: Decide if the factory has an owner or is fully trustless.

### B. Upgradable Proxy

- **Objective**: Make the curation system **upgradeable** to accommodate future logic changes or bug fixes.

- **Key Points**:
  1. **Proxy Pattern**: Use a well-established proxy mechanism (e.g., [OpenZeppelin’s Transparent or UUPS proxies](https://docs.openzeppelin.com/upgrades/latest/)).
  2. **Governance & Security**: Clarify who can initiate upgrades, how changes are proposed and approved, and ensure minimal disruption to staked tokens.
  3. **Storage Layout**: Demonstrate proper handling of storage variables to avoid collisions during upgrades.

### C. Uniswap Integration

- **Objective**: Automatically create liquidity on a DEX (e.g., Uniswap) for a successfully curated token.

- **Key Points**:
  1. **Automated Pool Creation**: After successful curation, deploy a **Uniswap pool** with additional **New Tokens** and the **CurationTokens** (instead of burning them) at the final ratio.



## Suggested Workflow

1. **Core Implementation**  
   - Build the staking, unstaking, and claiming mechanism.  
   - Ensure you handle edge cases like insufficient staked tokens, partial fulfillment, and security checks.

2. **Add Advanced Features (Optional)**  
   - **Factory Contract**: Write a factory that automatically deploys a new curation contract for each proposal.  
   - **Proxy Upgradeability**: Implement and test a proxy to upgrade the curation logic.  
   - **Uniswap Integration**: Integrate with Uniswap to add liquidity automatically upon successful curation.

3. **Testing & Security**  
   - Write thorough tests covering various scenarios (e.g., under/over target stake, reentrancy checks, etc.).  
   - Follow **security best practices** (e.g., checks-effects-interactions, access control, and input validation).



## Final Deliverables Recap

1. **Smart Contract(s) Code**  
   - **Core**: Staking, Unstaking, Claiming, and Security.  
   - **Optional**: Factory, Proxy Logic, and Uniswap Integration.

2. **Documentation**  
   - **Technical**: Explain design decisions, data flow, and contract architecture.  
   - **User Guide**: Show how to submit new tokens, stake tokens, and claim rewards (and, if implemented, how the factory, upgradeability, or liquidity provision works).

3. **Demonstration / Tests**  
   - Include an overview of your testing approach.  
   - Provide sample scripts or interactions demonstrating each feature.

