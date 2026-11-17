// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice One manually reviewed historical Orchard reproduction bounty on Sepolia.
/// @dev The reviewer checks RISC Zero receipts and the private report off-chain.
///      No proof verification or report delivery occurs in this contract.
contract HistoricalOrchardBounty {
    uint256 public constant REWARD = 0.001 ether;
    uint256 public constant REVIEW_PERIOD = 7 days;

    struct Claim {
        address claimant;
        bytes32 journalDigest;
        bytes32 reportCommitment;
    }

    address public immutable funder;
    address public immutable reviewer;
    bytes32 public immutable manifestDigest;
    uint256 public immutable deadline;

    mapping(bytes32 => Claim) public claims;
    bytes32 public approvedClaim;
    bool public paid;
    bool public refunded;

    event ClaimSubmitted(
        bytes32 indexed claimId, address indexed claimant, bytes32 journalDigest, bytes32 reportCommitment
    );
    event ClaimApproved(bytes32 indexed claimId, address indexed reviewer);
    event RewardWithdrawn(bytes32 indexed claimId, address indexed claimant, uint256 amount);
    event Refunded(address indexed funder, uint256 amount);

    error InvalidFunding();
    error InvalidConfiguration();
    error Closed();
    error InvalidClaim();
    error DuplicateClaim();
    error Unauthorized();
    error NotApproved();
    error TooEarly();
    error TransferFailed();

    constructor(address reviewer_, bytes32 manifestDigest_) payable {
        if (msg.value != REWARD) revert InvalidFunding();
        if (reviewer_ == address(0) || manifestDigest_ == bytes32(0)) revert InvalidConfiguration();
        funder = msg.sender;
        reviewer = reviewer_;
        manifestDigest = manifestDigest_;
        deadline = block.timestamp + REVIEW_PERIOD;
    }

    /// @notice The claimant must submit from the address bound into the receipt journal.
    function submit(bytes32 journalDigest, bytes32 reportCommitment) external returns (bytes32 claimId) {
        if (block.timestamp >= deadline || approvedClaim != bytes32(0) || refunded) revert Closed();
        if (msg.sender == reviewer) revert Unauthorized();
        if (journalDigest == bytes32(0) || reportCommitment == bytes32(0)) revert InvalidClaim();
        claimId = keccak256(abi.encode(block.chainid, address(this), msg.sender, journalDigest, reportCommitment));
        if (claims[claimId].claimant != address(0)) revert DuplicateClaim();
        claims[claimId] = Claim(msg.sender, journalDigest, reportCommitment);
        emit ClaimSubmitted(claimId, msg.sender, journalDigest, reportCommitment);
    }

    /// @notice Approval attests to the reviewer's off-chain verification, not on-chain proof checking.
    function approve(bytes32 claimId) external {
        if (msg.sender != reviewer) revert Unauthorized();
        if (block.timestamp >= deadline || approvedClaim != bytes32(0) || refunded) revert Closed();
        if (claims[claimId].claimant == address(0)) revert InvalidClaim();
        approvedClaim = claimId;
        emit ClaimApproved(claimId, msg.sender);
    }

    function withdraw() external {
        bytes32 claimId = approvedClaim;
        if (claimId == bytes32(0) || paid || claims[claimId].claimant != msg.sender) revert NotApproved();
        paid = true;
        (bool ok,) = payable(msg.sender).call{value: REWARD}("");
        if (!ok) revert TransferFailed();
        emit RewardWithdrawn(claimId, msg.sender, REWARD);
    }

    function refund() external {
        if (msg.sender != funder) revert Unauthorized();
        if (block.timestamp < deadline) revert TooEarly();
        if (approvedClaim != bytes32(0) || refunded) revert Closed();
        refunded = true;
        (bool ok,) = payable(funder).call{value: REWARD}("");
        if (!ok) revert TransferFailed();
        emit Refunded(funder, REWARD);
    }
}
