// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DecentralisedRaffle
 * @dev An advanced raffle smart contract with security features
 * @notice PART 2 - Decentralised Raffle (MANDATORY)
 */
contract DecentralisedRaffle {

    address public owner;
    uint256 public raffleId;
    uint256 public raffleStartTime;
    bool public isPaused;

    // --- TODO: Define additional state variables ---
    // Mapping to store each player's total entries.
    // address => number of entries
    mapping(address => uint255) public playerEntries;

    // Array to keep track of all entries, allowing for multiple entries per player.
    // Each element is the address of the player who made that specific entry.
    address[] public allEntries;

    // Total ETH collected in the raffle pot.
    uint256 public totalPot;

    // A list of unique players for checking the minimum player requirement.
    // Using a mapping to quickly check if an address is already unique.
    mapping(address => bool) private uniquePlayersTracker;
    address[] public uniquePlayers; // To iterate or count easily.

    // State to prevent reentrancy during ether transfers
    bool private locked;

    // Events
    event RaffleEntry(address indexed player, uint256 entriesSoFar, uint256 totalPot);
    event WinnerSelected(address indexed winner, uint256 prizeAmount, uint256 ownerFee);
    event RafflePaused();
    event RaffleUnpaused();

    constructor() {
        owner = msg.sender;
        raffleId = 1;
        raffleStartTime = block.timestamp;
        isPaused = false;
        locked = false; // Initialize reentrancy guard
    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    // Reentrancy guard modifier
    modifier noReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // --- TODO: Implement entry function ---
    // Requirements:
    // - Players pay minimum 0.01 ETH to enter
    // - Track each entry (not just unique addresses)
    // - Allow multiple entries per player
    // - Emit event with player address and entry count
    function enterRaffle() public payable whenNotPaused {
        // Validation: Check minimum entry amount
        require(msg.value >= 0.01 ether, "Minimum entry amount is 0.01 ETH");

        // Calculate number of entries based on the sent amount
        uint256 numEntries = msg.value / 0.01 ether;
        require(numEntries > 0, "Must purchase at least one entry");

        // Track each entry
        for (uint256 i = 0; i < numEntries; i++) {
            allEntries.push(msg.sender);
        }

        // Update player's total entries
        playerEntries[msg.sender] += numEntries;

        // Update unique players list
        if (!uniquePlayersTracker[msg.sender]) {
            uniquePlayersTracker[msg.sender] = true;
            uniquePlayers.push(msg.sender);
        }

        // Update total pot
        totalPot += msg.value;

        // Emit event
        emit RaffleEntry(msg.sender, playerEntries[msg.sender], totalPot);
    }

    // --- TODO: Implement winner selection function ---
    // Requirements:
    // - Only owner can trigger
    // - Select winner from TOTAL entries (not unique players)
    // - Winner gets 90% of pot, owner gets 10% fee
    // - Use a secure random mechanism (better than block.timestamp)
    // - Require at least 3 unique players
    // - Require raffle has been active for 24 hours
    function selectWinner() public onlyOwner noReentrant {
        // Validation: Check minimum unique players
        require(uniquePlayers.length >= 3, "At least 3 unique players are required");

        // Validation: Check if raffle has been active for 24 hours
        require(block.timestamp >= raffleStartTime + 24 hours, "Raffle must be active for at least 24 hours");

        // Validation: Ensure there are entries to select a winner from
        require(allEntries.length > 0, "No entries in the raffle");

        // --- CHALLENGE: How do you generate randomness securely? ---
        // Using Chainlink VRF (Verifiable Random Function) is the most secure way for production.
        // For a simpler, non-production example, we'll use a pseudo-random approach with blockhash
        // combined with current block data. This is still NOT truly secure for high-value raffles,
        // as miners could manipulate blockhash to some extent if they benefit.
        // A better approach for serious projects involves Chainlink VRF or a similar oracle.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, msg.sender, allEntries.length))) % allEntries.length;

        address winner = allEntries[randomNumber];

        // Calculate prize and owner fee
        uint256 prizeAmount = totalPot * 90 / 100;
        uint256 ownerFee = totalPot - prizeAmount; // Or totalPot * 10 / 100

        // Transfer prize to winner
        (bool successWinner, ) = winner.call{value: prizeAmount}("");
        require(successWinner, "Failed to send prize to winner");

        // Transfer owner fee
        (bool successOwner, ) = owner.call{value: ownerFee}("");
        require(successOwner, "Failed to send owner fee");

        // Emit winner event
        emit WinnerSelected(winner, prizeAmount, ownerFee);

        // Reset raffle for the next round
        _resetRaffle();
    }

    // Internal function to reset raffle state
    function _resetRaffle() internal {
        raffleId++;
        raffleStartTime = block.timestamp;
        allEntries = new address[](0); // Clear all entries
        playerEntries = new mapping(address => uint255); // Clear player specific entries
        totalPot = 0;
        uniquePlayers = new address[](0); // Clear unique players
        // Reset uniquePlayersTracker by creating a new mapping (or iterating and deleting)
        // This is less efficient but ensures cleanliness for the example.
        // A more gas-efficient way for a very large uniquePlayersTracker would be
        // to not clear it if storage is not an issue, or to use an array and delete.
        // For this example, let's assume `playerEntries` and `uniquePlayersTracker`
        // being reset is fine.
        // For `uniquePlayersTracker`, we'd ideally iterate `uniquePlayers` and set
        // `uniquePlayersTracker[player] = false;` if not recreating the mapping.
        // For simplicity, we are essentially recreating the mapping by assigning `new mapping(...)`
        // but this operation is a bit nuanced with storage pointers in Solidity.
        // A safer way to clear a mapping completely after use (if not just resetting pointers)
        // is usually handled by destroying and redeploying the contract, or iterating and deleting.
        // For `uniquePlayersTracker`, let's just make sure to handle it correctly.
        // Since `playerEntries` gets overwritten, the previous data becomes inaccessible.
        // To be explicit for `uniquePlayersTracker`:
        for (uint256 i = 0; i < uniquePlayers.length; i++) {
            delete uniquePlayersTracker[uniquePlayers[i]];
        }
    }

    // --- TODO: Implement circuit breaker (pause/unpause) ---
    // Requirements:
    // - Owner can pause raffle in emergency
    // - Owner can unpause raffle
    // - When paused, no entries allowed
    function pause() public onlyOwner {
        require(!isPaused, "Raffle is already paused");
        isPaused = true;
        emit RafflePaused();
    }

    function unpause() public onlyOwner {
        require(isPaused, "Raffle is not paused");
        isPaused
    }
}