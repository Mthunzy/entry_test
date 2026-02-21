# Part A: MCQ Answers

**Status:** [In Progress / Submitted]  

---

## Instructions
**COMPLETE ALL QUESTIONS FOR BOTH PART 1 AND PART 2 BELOW**

---

## PART 1: Renewable Energy Trading Platform (Real-World African Context)

**Scenario:** You are hired as a blockchain developer to build a decentralised renewable energy marketplace for African solar micro-grid providers. The platform must:

- Allow providers to list solar energy credits as NFTs with generation certificates  
- Enable buyers to swap tokens for energy credits using a DEX  
- Store provider reputation scores transparently  
- Process payments without intermediaries  

---

### Question 1: Architecture Decision (Technical Reasoning)

**Which combination of technologies demonstrates the best understanding of blockchain fundamentals for this use case?**

- **A)** Use ERC-721 for each energy credit, build a centralised database for reputation, and integrate Binance for payments because CEXs have better liquidity.  
- **B)** Use ERC-1155 for energy credits (enabling batch listings from providers), implement reputation as on-chain mappings in the marketplace smart contract, and integrate with a DEX like Uniswap for direct provider-to-buyer swaps to minimise intermediaries.  
- **C)** Use ERC-721 exclusively, store all data off-chain for gas savings, and require buyers to use MetaMask with manual price negotiations.  
- **D)** Build everything as separate NFT collections with no DEX integration since providers won't understand DeFi protocols.  

**Your Answer:** [A/B/C/D]  
             : B

**Your Reasoning:**  
[2–3 sentences explaining why you chose this answer. What makes it the best choice?]  

Option B best leverages blockchain's strengths for this use case. ERC-1155 tokens are efficient for batch listing energy credits, crucial for providers. Storing reputation on-chain ensures transparency and immutability, while integrating with a DEX like Uniswap directly fulfills the need for intermediary-free, trustless swaps between providers and buyers, aligning with decentralization principles.

---

### Question 2: Cost Optimisation (Practical Aptitude)

A solar micro-grid provider wants to list 40 energy credit bundles. Gas costs are:

- **ERC-721:** 100,000 gas per NFT mint  
- **ERC-1155:** 150,000 gas for first mint + 5,000 gas per additional item in batch  

**Current gas price:** 20 gwei  
**1 ETH = $3,000**

**What is the gas cost difference between ERC-721 and ERC-1155 for listing 40 items?**

- **A)** ERC-721 is cheaper by $15  
- **B)** ERC-1155 is cheaper by approximately $27  
- **C)** They cost exactly the same  
- **D)** ERC-1155 is cheaper by approximately $180  

**Your Answer:** [A/B/C/D]  
             : D

**Your Calculation/Reasoning:**  

    ERC-721 Total Gas: 40 items * 100,000 gas/item = 4,000,000 gas
    ERC-1155 Total Gas: 150,000 gas (initial) + (39 items * 5,000 gas/item) = 150,000 + 195,000 = 345,000 gas
    Gas Difference: 4,000,000 gas - 345,000 gas = 3,655,000 gas
    Gas Price: 20 gwei = 0.000000020 ETH
    ETH Price: $3,000
    Cost Difference in USD: 3,655,000 gas * 0.000000020 ETH/gas * $3,000/ETH = $219.30

- ERC-721 cost = [Show calculation]
               = 100,000 * 40
               = 4,000,000 * 0.026
               = 104,000
- ERC-1155 cost = [Show calculation]
                = 150,000 + 5,000*39
                = 345,000 * 0.026
                = 8,970
- Difference = [Show calculation]


[Explain why gas optimisation matters for African users]  

Cost is King: High transaction fees (gas fees) can really hit hard, especially in regions where disposable income might be lower. If a simple crypto transaction costs a significant percentage of the amount being transferred, it makes using blockchain applications impractical for many people. Optimized gas usage means lower fees, which makes crypto more accessible and affordable for a wider audience.
Encourages Adoption: When transaction costs are low and predictable, more people are likely to try out and regularly use blockchain-based services like DeFi (Decentralized Finance) or NFTs. High, unpredictable fees are a major turn-off and can stop mainstream adoption in its tracks.
Enables More Use Cases: Lower gas costs mean that more frequent and complex interactions on the blockchain become viable. This can open up opportunities for micro-transactions, remittances, or other services that wouldn't make sense if each small operation incurred a hefty fee. Gas optimization allows for more sophisticated functionality within reasonable cost limits.
Fairer Access: Without gas optimization, only "whales" (users with large capital) might be able to efficiently participate in certain DeFi strategies or NFT mints, creating a barrier to entry for smaller retail users. Optimization helps level the playing field. 
---

### Question 3: Value Proposition Explanation (Communication & Thinking)

A micro-grid provider asks: *"Why can't we just use a normal website with a database?"*

**Which response demonstrates understanding of blockchain's actual value (not just its technology)?**

- **A)** "Blockchain is the future; everyone should use it."  
- **B)** "With blockchain, no middleman can manipulate your pricing or payment records. If a buyer claims they paid but you didn't receive funds, the blockchain provides immutable proof. Plus, your reputation score can follow you to other platforms since it's on-chain – it's your data, not the platform's."  
- **C)** "Because smart contracts are more secure than databases and Web3 is decentralised."  
- **D)** "Blockchain uses cryptography which makes it unhackable, unlike normal databases."  

**Your Answer:** [A/B/C/D]  

**Your Explanation:**  
[2–3 sentences explaining what makes this answer correct. What did you learn about why blockchain matters in Africa?]  

---

## PART 2: DeFi & NFT Integration (Advanced Concepts)

**Scenario:** A DeFi protocol experiences the following sequence of events:

- A liquidity provider adds 5 ETH and 15,000 USDC to an AMM pool (constant product formula: x × y = k)  
- A trader swaps 1 ETH for USDC (no fees for simplicity)  
- The protocol's governance token holders vote on implementing impermanent loss protection  
- An NFT marketplace integrates with the DEX to enable ERC-1155 token swaps  

---

### Question: Multi-Concept Synthesis

**Which statement correctly combines understanding of AMMs, governance, and technical implementation?**

- **A)** After the 1 ETH swap, the liquidity provider will have exactly the same USD value as before because the constant product formula maintains equal ratios. ERC-1155 tokens cannot be traded on AMMs since they support both fungible and non-fungible characteristics.  
- **B)** The trader will receive approximately 2,500 USDC from the swap (calculated using k = 5 × 15,000 = 75,000, then 6 × y = 75,000). Impermanent loss protection would compensate the LP for price divergence between the pool ratio and external market prices. ERC-1155's batch transfer capability makes it more gas-efficient than ERC-721 for marketplace integration.  
- **C)** The liquidity provider experiences impermanent loss because the pool maintains a constant product rather than constant ratio. ERC-721 would be more suitable than ERC-1155 for the NFT marketplace since individual NFTs require unique transactions.  
- **D)** The constant product formula prevents any impermanent loss by automatically rebalancing. DAOs cannot implement financial protections due to smart contract immutability. ERC-1155 tokens are incompatible with standard DEX protocols.  

**Your Answer:** [A/B/C/D]  

**Your Reasoning:**  

- **AMM Mathematics:** How do you calculate the swap output? What happens to the liquidity provider's value?  
- **DeFi Governance:** What is impermanent loss and how does protection work?  
- **Token Standards:** Why might ERC-1155 be preferred over ERC-721 for marketplace integration?  

[2–3 sentences synthesising these concepts into a coherent explanation]  

---

## SUBMISSION CHECKLIST

- You answered all questions for **BOTH PART 1 AND PART 2**  
- Your answers include reasoning (not just A/B/C/D)  
- For PART 1 Q2: You showed your gas cost calculations  
- For PART 2: You addressed all three concept areas (AMM, Governance, Token Standards)  
- You committed and pushed to GitLab  

---

**Challenges faced:** [What was difficult? Which concepts are you less confident about?]  