# Part B: Test Scenarios Guide

**Complete test scenarios for BOTH contracts.**

---

## Test Scenario 1: FreelanceBountyBoard
**Target:** `FreelanceBountyBoard.sol`
1.1 Happy path

Description: Successful bounty posting, application, submission, and payment.
Steps:

    Alice (employer) calls postBounty("Build landing page", "WebDev") with 1 ETH.
    Bob registers via registerFreelancer("WebDev").
    Bob calls applyForBounty(0).
    Bob calls submitWork(0, "https://github.com/bob/proof").
    Alice calls approveAndPay(0, bob).

Expected result:

    Bounty struct updated: completed = true, winner = bob, amount = 0.
    Bob receives 1 ETH (minus gas).
    Events emitted: BountyPosted, FreelancerRegistered, AppliedForBounty, WorkSubmitted, BountyPaid.
    Contract balance decreases by 1 ETH.

1.2 Security/edge case

Description: Reentrancy attempt + unauthorized approval.
Steps:

    Mallory deploys attacker contract that calls approveAndPay then, in its receive() fallback, re-calls approveAndPay for same bounty.
        Also test: Carol (not employer) tries approveAndPay(0, bob).
    Test double-approval: Alice calls approveAndPay(0, bob) twice.

Expected result:

    Reentrancy: second call reverts/returns without paying (guard prevents recursive entry, completed already true or locked blocks).
    Unauthorized call: reverts with “Not employer” (require fails).
    Double-approval: second call reverts (“Already paid” or completed check).
    Contract balance changes only once; Bob paid once. All events emitted exactly once.

## Test Scenario 2: DecentralisedRaffle
**Target:** `DecentralisedRaffle.sol`

.1 Happy path

Description: Multiple entrants, VRF draw, payout. Steps:

    Alice buys 3 tickets via buyTickets{value: 0.3 ETH}() (0.1 ETH each).
    Bob buys 2 tickets via buyTickets{value: 0.2 ETH}().
    Owner calls requestDraw() (emits Chainlink request).
    Chainlink node calls fulfillRandomWords(requestId, ).
    Contract computes winner: 42 mod 5 = 2 → tickets [0-2 Alice, 3-4 Bob] → Alice wins.
    Payout transfers 0.5 ETH * 0.95 (5% fee) to Alice; fee remains in contract.*

Expected result:

    Winner = Alice, players array/map reset, prizePool = 0.
    Alice’s balance increases by 0.475 ETH.
    Events: TicketsPurchased, DrawRequested, WinnerSelected.
    Contract retains fee (0.025 ETH).

2.2 Security/edge case

Description: Randomness manipulation attempt + insufficient funds. Steps:

    Eve tries requestDraw() before any tickets sold.
    Owner tries to call fulfillRandomWords directly with a chosen random word.
    Test calling buyTickets after draw but before state reset.
    
Expected result:

    Draw with zero tickets reverts (“No tickets”).
    Direct call to fulfillRandomWords fails: only VRF coordinator can call (modifier or require), or requestId mismatch reverts.
    Buying tickets after requestDraw but before callback either reverts (draw lock) or queues for next round — design choice, but must not affect current randomness. No overwriting of randomness; winner chosen fairly from pre-draw pool.

---

## Coverage Assessment
After implementing your tests in `test/`, assess your coverage:
1. **Link to test files:** (e.g., `test/FreelanceBountyBoard.test.js`)
2. **Key functions tested:**
3. **Estimated Coverage:** (Aim for 80%+)

> [!TIP]
> Use `npx hardhat coverage` if you have the plugin installed, otherwise manually verify all state transitions are tested.
