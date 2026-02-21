// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title FreelanceBountyBoard
 * @dev Decentralised marketplace for skills and bounties
 */
contract FreelanceBountyBoard {
    address public owner;

    // --- State variables ---
    struct Freelancer {
        string skill;
        bool registered;
    }

    struct Bounty {
        address employer;
        string description;
        string skillRequired;
        uint256 amount;
        bool completed;
        address winner;
        mapping(address => bool) applicants;
        mapping(address => bool) hasSubmitted;
    }

    mapping(address => Freelancer) public freelancers;
    mapping(uint256 => Bounty) private bounties;
    uint256 public nextBountyId;

    // Reentrancy guard (simple nonReentrant)
    bool private locked;

    // --- Events ---
    event FreelancerRegistered(address indexed freelancer, string skill);
    event BountyPosted(uint256 indexed bountyId, address indexed employer, string skillRequired, uint256 amount);
    event AppliedForBounty(uint256 indexed bountyId, address indexed freelancer);
    event WorkSubmitted(uint256 indexed bountyId, address indexed freelancer, string submissionUrl);
    event BountyPaid(uint256 indexed bountyId, address indexed freelancer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // --- Freelancer functions ---
    function registerFreelancer(string memory skill) public {
        require(!freelancers[msg.sender].registered, "Already registered");
        freelancers[msg.sender] = Freelancer(skill, true);
        emit FreelancerRegistered(msg.sender, skill);
    }

    // --- Bounty lifecycle ---
    function postBounty(string memory description, string memory skillRequired) public payable {
        require(msg.value > 0, "Must send ETH");
        uint256 bountyId = nextBountyId++;
        Bounty storage b = bounties[bountyId];
        b.employer = msg.sender;
        b.description = description;
        b.skillRequired = skillRequired;
        b.amount = msg.value;
        b.completed = false;
        emit BountyPosted(bountyId, msg.sender, skillRequired, msg.value);
    }

    function applyForBounty(uint256 bountyId) public {
        Freelancer memory f = freelancers[msg.sender];
        Bounty storage b = bounties[bountyId];
        require(f.registered, "Not a freelancer");
        require(keccak256(bytes(f.skill)) == keccak256(bytes(b.skillRequired)), "Skill mismatch");
        require(!b.applicants[msg.sender], "Already applied");
        b.applicants[msg.sender] = true;
        emit AppliedForBounty(bountyId, msg.sender);
    }

    function submitWork(uint256 bountyId, string memory submissionUrl) public {
        Bounty storage b = bounties[bountyId];
        require(b.applicants[msg.sender], "Did not apply");
        require(!b.hasSubmitted[msg.sender], "Already submitted");
        b.hasSubmitted[msg.sender] = true;
        emit WorkSubmitted(bountyId, msg.sender, submissionUrl);
    }

    function approveAndPay(uint256 bountyId, address freelancer) public nonReentrant {
        Bounty storage b = bounties[bountyId];
        require(msg.sender == b.employer, "Not employer");
        require(!b.completed, "Already paid");
        require(b.applicants[freelancer], "Freelancer did not apply");
        require(b.hasSubmitted[freelancer], "No submission");

        // effects
        b.completed = true;
        b.winner = freelancer;
        uint256 payout = b.amount;
        b.amount = 0;

        // interaction
        (bool ok,) = freelancer.call{value: payout}("");
        require(ok, "Transfer failed");

        emit BountyPaid(bountyId, freelancer, payout);
    }

    // --- Helpers ---
    function getBounty(uint256 bountyId) public view returns (
        address employer,
        string memory description,
        string memory skillRequired,
        uint256 amount,
        bool completed,
        address winner
    ) {
        Bounty storage b = bounties[bountyId];
        return (b.employer, b.description, b.skillRequired, b.amount, b.completed, b.winner);
    }

    function isFreelancer(address addr) public view returns (bool) {
        return freelancers[addr].registered;
    }
}