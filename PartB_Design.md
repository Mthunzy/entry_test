# Part B: Design Document

**Section 1: FreelanceBountyBoard (Renewable Energy Platform)**

**Section 2: DecentralisedRaffle (DeFi & NFT Integration)**

---

## WHY I BUILT IT THIS WAY

### 1. Data Structure Choices
**Explain your design decisions for BOTH contracts:**
- When would you choose to use a `mapping` instead of an `array`?
- How did you structure your state variables in `FreelanceBountyBoard` vs `DecentralisedRaffle`?
- What trade-offs did you consider for storage efficiency?

[Write your response here]
Mapping is useful when:

    You need efficient lookup of a value associated with a unique key. Think of it like a dictionary where you instantly get the value once you have the key. It's super fast for retrieving, updating, or deleting specific items if you know their identifier.
    You don't need to iterate over all elements. Mappings aren't iterable by default, so if you need to list all entries, a mapping alone isn't the best fit.
    You have sparse data or potentially very large datasets, as mappings don't store "empty" slots and don't have the overhead of resizing.
    In the DecentralisedRaffle, you'd likely use a mapping to keep track of participants and their entries, perhaps mapping(address => uint) public participantEntries;, because you'd quickly want to check how many entries a specific address has.

An array is useful when:

    You need to maintain an ordered list of elements. Arrays keep elements in the order they were added, which is great if order matters.
    You need to iterate over all elements. You can easily loop through an array to process each item.
    The size of the collection is relatively small or can be managed without excessive gas costs for resizing (for dynamic arrays) or large initial deployment costs (for fixed-size arrays).
    In the FreelanceBountyBoard, an array could be useful for storing a list of active bounty IDs or an array of Bounty structs if you wanted to easily retrieve all bounties to display them on a front-end. For example, Bounty[] public bounties;.
---

### 2. Security Measures
**What attacks did you protect against in BOTH implementations?**
- Reentrancy attacks? (Explain your implementation of the Checks-Effects-Interactions pattern)
- Access control vulnerabilities?
- Integer overflow/underflow?
- Front-running/Randomness manipulation (specifically for `DecentralisedRaffle`)?

[Write your response here]
. Reentrancy attacks

How it’s handled
 In FreelanceBountyBoard.approveAndPay, I used the checks-effects-interactions pattern plus a simple nonReentrant guard:
        Checks: verify msg.sender is employer, bounty not yet paid, freelancer applied and submitted.
        Effects: update state first (b.completed = true, b.amount = 0) before any external call.
        Interactions: transfer ETH with call after state changes.
    The modifier sets locked = true for the duration of the function, blocking recursive entry even if a malicious fallback tries to call back in.

For the raffle (see Part 2), the same pattern applies to buyTickets and especially to requestDraw/fulfillRandomness: state changes (recording drawId, marking winners, resetting pool) happen before any external callback or transfer.
2. Access control vulnerabilities

    Freelance board: employer-only approval is enforced with require(msg.sender == b.employer). No function lets outsiders mutate a bounty they didn’t post.
    Raffle: requestDraw is restricted to owner (onlyOwner modifier). Payouts only go to addresses in playerTickets; no arbitrary address can trigger fund movement.
    Registration/application checks prevent unregistered users from applying.
3. Integer overflow/underflow

    Solidity ^0.8.18 has built-in overflow/underflow reverts, so arithmetic is safe by default. I don’t use unchecked blocks, meaning every +, -, * will revert on overflow rather than wrap.
    For the raffle, ticket counts and pools are uint256; pool balance is tracked alongside msg.value, and winnings are validated against the pool before transfer.*

4. Front-running / Randomness manipulation (Part 2: raffle)

    Problem: block attributes (block.timestamp, blockhash, msg.sender nonce) are predictable/miner-influenced, so they’re unsafe for picking winners.
    Mitigation: I avoided on-chain-only randomness. The raffle uses Chainlink VRF for the draw:
        Players buy tickets, state is recorded.
        Owner calls requestDraw → requests VRF randomness (unpredictable, verifiable).
        fulfillRandomWords (called by Chainlink) receives the proof + random word; winner selection derives from that value.
        Because VRF output isn’t known until the callback, neither users nor the owner can front-run or grind to manipulate the winner.
    If no Chainlink subscription were available, I’d fall back to a commit-reveal scheme with a blockhash from a future block, but VRF is the cleaner solution.

---

### 3. Trade-offs & Future Improvements
**What would you change with more time?**
- Gas optimization opportunities?
- Additional features (e.g., dispute resolution, multiple prize tiers)?
- Better error handling?

[Write your response here]
Gas optimization opportunities

    Strings & storage: Both contracts store string values (skills, descriptions, submissions). That’s convenient but costly.
        Future fix: store bytes32 skill IDs (hashes of canonical skill names) and use IPFS/Content-ID hashes for descriptions/submissions, saving storage gas.
    Mappings inside structs: Bounty contains nested mappings (applicants, hasSubmitted). Solidity stores these in separate slots, which is fine for simplicity but reading/writing them can be expensive.
        Future fix: use incremental arrays + index mappings if we need enumeration, or accept off-chain indexing via events and drop the on-chain applicant mapping entirely.
    Reentrancy guard: The boolean locked adds a tiny cost. For a single protected function this is fine; for many, OpenZeppelin’s ReentrancyGuard (status=1/2) is slightly more robust but similar gas. No big win here unless we refactor to a pull-payment model and remove external calls from critical paths.

---

## REAL-WORLD DEPLOYMENT CONCERNS

### 1. Gas Costs
**Analyze the viability of your contracts for real-world use:**
- Estimated gas for key functions (e.g., `postBounty`, `selectWinner`).
- Is this viable for users in constrained environments (e.g., high gas fees)?
- Any specific optimization strategies you implemented?

[Write your response here]
Estimated gas for key functions

    registerFreelancer: ∼45–55k gas (writes one struct, emits event).
    postBounty: ∼90–120k gas (creates new struct, writes 4–5 storage slots, emits event). If we pass a long description string, calldata and SSTORE costs rise linearly.
    applyForBounty: ∼40–55k gas (skill check + mapping write).
    submitWork: ∼35–50k gas.
    approveAndPay: ∼60–80k gas (state updates + external call; refunds reduce net cost if b.amount set to 0).
    Raffle buyTickets: ∼50–70k gas per player (update mapping, emit event, accept ETH).
    Raffle requestDraw: ∼70–100k gas (onlyOwner check, Chainlink request emit, storing requestId).
    Raffle fulfillRandomWords: ∼80–120k gas (callback writes winner, computes share, transfers ETH).

Viability in constrained environments

    At today’s (∼30 gwei) high-fee periods, 100k gas ≈ $3–6 USD, which is acceptable for bounties of meaningful size but painful for micro-bounties (<$10) or buying a single raffle ticket.
    The contracts are usable but not ideal for low-value interactions. Users would batch actions or only post higher-value bounties/raffles to amortize fees.
    On L2s (Optimism, Arbitrum) or gas-refunding chains, costs would collapse to cents, making them much more practical.

---

### 2. Scalability
**What happens with 10,000+ entries/bounties?**
- Performance considerations for loops or large arrays.
- Storage cost implications.
- Potential bottlenecks in `selectWinner` or `applyForBounty`.

[Write your response here]
Loops & large arrays

    Current design avoids loops: I never iterate over bounties or applicants on-chain. Functions like applyForBounty and selectWinner touch only constant-time storage slots (mappings keyed by address/bountyId). That means performance doesn’t degrade as the system grows.
    What would break: If we added a getAllBounties that returns an array, or tried to pick a winner by looping through a ticket list, gas would explode (>100k per iteration) and hit block limits. I purposely kept data in mappings and emitted events for off-chain indexing instead.

Storage cost implications

    Each new Bounty costs ∼4–5 SSTOREs (20k gas each when zero→nonzero). 10,000 bounties ≈ 200 million gas total over time — fine as a running system (cost paid by posters), but the contract’s state size grows. Nodes need to store all those slots, but that’s normal for Ethereum; read costs stay low.
    Freelancer registry also grows linearly, but lookups are O(1) via freelancers
---

### User Experience

**How would you make this usable for non-crypto users?**
- Onboarding process?
- MetaMask alternatives?
- Mobile accessibility?

[Write about your UX(user experience) considerations]
User experience for non-crypto users
Onboarding process

    Hide raw keys/wallets behind email or social login. Use a smart-wallet provider (e.g., Privy, Web3Auth, or Magic.link) to create an embedded wallet when someone signs up, then sponsor their gas for first actions.
    Walk them through a “post a bounty” demo with test tokens before touching real ETH. Show progress: “You’re registering a skill → skill saved” rather than “Transaction sent.”
    For raffles, abstract tickets: let users buy with a card, backend swaps to ETH and calls contract.

MetaMask alternatives

    MetaMask is friction for newbies. Offer account-abstraction (ERC-4337) wallets with passkey/biometric unlock, so they never see seed phrases.
    Provide a custodial-lite option: user has a login, we hold a scoped wallet, and expose a withdraw button when they’re ready. Later migrate to full self-custody.
    Group actions (apply + submit) into one UI step so they sign once per bounty, not per sub-action.

---

## MY LEARNING APPROACH

### Resources I Used

**Show self-directed learning:**
- Documentation consulted
- Tutorials followed
- Community resources

[List 3-5 resources you used]
- **[Solidity Docs](https://docs.soliditylang.org/)** - Complete language reference
- **[Solidity by Example](https://solidity-by-example.org/)** - Practical code examples
- **[OpenZeppelin Docs](https://docs.openzeppelin.com/)** - Secure contract libraries
- **[Remix IDE](https://remix.ethereum.org/)** - Browser-based development environment

---

### Challenges Faced

**Problem-solving evidence:**
- Biggest technical challenge
- How you solved it
- What you learned

[Write down your challenges]

---

### What I'd Learn Next

**Growth mindset indicator:**
- Advanced Solidity patterns
- Testing frameworks
- Frontend integration

[Write your future learning goals]

---
