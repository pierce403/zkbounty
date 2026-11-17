// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {HistoricalOrchardBounty} from "../contracts/HistoricalOrchardBounty.sol";

interface Vm {
    function deal(address who, uint256 newBalance) external;
    function prank(address caller) external;
    function warp(uint256 timestamp) external;
    function expectRevert(bytes4 selector) external;
}

contract HistoricalOrchardBountyTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant FUNDER = address(0xF00D);
    address private constant REVIEWER = address(0xBEEF);
    address private constant CLAIMANT = address(0xCAFE);
    address private constant STRANGER = address(0xDEAD);
    bytes32 private constant MANIFEST = bytes32(uint256(1));
    bytes32 private constant JOURNAL = bytes32(uint256(2));
    bytes32 private constant REPORT = bytes32(uint256(3));

    HistoricalOrchardBounty private bounty;

    function setUp() public {
        vm.deal(FUNDER, 1 ether);
        vm.prank(FUNDER);
        bounty = new HistoricalOrchardBounty{value: 0.001 ether}(REVIEWER, MANIFEST);
    }

    function testApprovedClaimCanWithdrawExactlyOnce() public {
        vm.prank(CLAIMANT);
        bytes32 claimId = bounty.submit(JOURNAL, REPORT);
        (address claimant, bytes32 journal, bytes32 report) = bounty.claims(claimId);
        require(claimant == CLAIMANT && journal == JOURNAL && report == REPORT, "claim context");

        vm.prank(REVIEWER);
        bounty.approve(claimId);
        vm.prank(STRANGER);
        vm.expectRevert(HistoricalOrchardBounty.NotApproved.selector);
        bounty.withdraw();

        uint256 beforeBalance = CLAIMANT.balance;
        vm.prank(CLAIMANT);
        bounty.withdraw();
        require(CLAIMANT.balance == beforeBalance + 0.001 ether, "wrong payout");
        require(address(bounty).balance == 0 && bounty.paid(), "escrow not closed");

        vm.prank(CLAIMANT);
        vm.expectRevert(HistoricalOrchardBounty.NotApproved.selector);
        bounty.withdraw();
        vm.prank(CLAIMANT);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.submit(JOURNAL, REPORT);
    }

    function testOnlyReviewerCanApproveAnExistingClaim() public {
        vm.prank(CLAIMANT);
        bytes32 claimId = bounty.submit(JOURNAL, REPORT);
        vm.prank(STRANGER);
        vm.expectRevert(HistoricalOrchardBounty.Unauthorized.selector);
        bounty.approve(claimId);
        vm.prank(REVIEWER);
        vm.expectRevert(HistoricalOrchardBounty.InvalidClaim.selector);
        bounty.approve(bytes32(uint256(9)));
        vm.prank(REVIEWER);
        bounty.approve(claimId);
        vm.prank(REVIEWER);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.approve(claimId);
    }

    function testDuplicateAndEmptyClaimsFail() public {
        vm.prank(CLAIMANT);
        bounty.submit(JOURNAL, REPORT);
        vm.prank(CLAIMANT);
        vm.expectRevert(HistoricalOrchardBounty.DuplicateClaim.selector);
        bounty.submit(JOURNAL, REPORT);
        vm.prank(STRANGER);
        vm.expectRevert(HistoricalOrchardBounty.InvalidClaim.selector);
        bounty.submit(bytes32(0), REPORT);
        vm.prank(REVIEWER);
        vm.expectRevert(HistoricalOrchardBounty.Unauthorized.selector);
        bounty.submit(JOURNAL, REPORT);
    }

    function testFunderRefundsOnlyAfterDeadlineWithoutApproval() public {
        vm.prank(FUNDER);
        vm.expectRevert(HistoricalOrchardBounty.TooEarly.selector);
        bounty.refund();
        vm.prank(CLAIMANT);
        bytes32 claimId = bounty.submit(JOURNAL, REPORT);
        vm.warp(bounty.deadline());
        vm.prank(REVIEWER);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.approve(claimId);
        vm.prank(CLAIMANT);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.submit(JOURNAL, REPORT);
        vm.prank(STRANGER);
        vm.expectRevert(HistoricalOrchardBounty.Unauthorized.selector);
        bounty.refund();

        uint256 beforeBalance = FUNDER.balance;
        vm.prank(FUNDER);
        bounty.refund();
        require(FUNDER.balance == beforeBalance + 0.001 ether, "wrong refund");
        require(bounty.refunded() && address(bounty).balance == 0, "escrow not refunded");
        vm.prank(FUNDER);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.refund();
    }

    function testApprovalReservesFundsAfterDeadline() public {
        vm.prank(CLAIMANT);
        bytes32 claimId = bounty.submit(JOURNAL, REPORT);
        vm.prank(REVIEWER);
        bounty.approve(claimId);
        vm.warp(bounty.deadline());
        vm.prank(FUNDER);
        vm.expectRevert(HistoricalOrchardBounty.Closed.selector);
        bounty.refund();
        vm.prank(CLAIMANT);
        bounty.withdraw();
        require(bounty.paid(), "approved claimant cannot withdraw");
    }

    function testInvalidDeploymentFails() public {
        vm.deal(FUNDER, 1 ether);
        vm.prank(FUNDER);
        vm.expectRevert(HistoricalOrchardBounty.InvalidFunding.selector);
        new HistoricalOrchardBounty{value: 0}(REVIEWER, MANIFEST);
        vm.prank(FUNDER);
        vm.expectRevert(HistoricalOrchardBounty.InvalidConfiguration.selector);
        new HistoricalOrchardBounty{value: 0.001 ether}(address(0), MANIFEST);
    }
}
