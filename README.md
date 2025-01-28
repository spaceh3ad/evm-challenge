# evm-challenge

# Token Launch Curation Challenge

## Overview
The goal is to build a **smart contract system** that enables **community-driven curation** of new token launchesn (**New Token**) using an **existing ERC20 token (CurationToken)** as the curation mechanism.

## The Challenge
Create a system where **curators stake tokens** to vote on the **legitimacy of new token launches**. Curators stake the **CurationToken** to signal their interest in the **New Token**.

---

## Core Requirements

### 1. **Token Launch Submission**
Curators must evaluate and vote on submitted token launches. Submissions should include:

- **Token Address**: The contract address of the submitted token.
- **New Token To be Distributed**: The amount of **New Tokens** that will be distributed if the curation is successful.
- **CurationTokens Target**: The amount of **CurationTokens** needed to have a successful curation.

---

### 2. **Curation Mechanism**

#### **Stake Tokens**
- Participants must stake **CurationToken** (an existing ERC20 token) to curate token launches.

#### **Unstake Tokens**
- Participants can unstake their **CurationTokens** after a certain amount of time.

#### **Successful Curation**
- If enough tokens are staked, the curation is considered a success. The **CurationTokens** are burnt and participants can claim their share of **New Tokens** 

---

## Deliverables
- **Smart Contract Code**:
  - Staking mechanism
  - Unstaking mechanism
  - Claiming mechanism
  - Security best practices
- **Documentation**:
  - Technical documentaion of the system explaining design choices.
  - User guide for curators and token submitters.
---
