// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../Fixture.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";

contract CurationTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_stake() public {
        (
            address curationInstance,
            CurationDetails memory curationDetails
        ) = createSubmission(deployer);

        CurationDetails memory _curationDetails = Curation(curationInstance)
            .getCurationDetails();

        assertEq(
            address(_curationDetails.curationToken),
            address(curationToken)
        );

        uint256 bobStakeAmount = 50_000 ether;

        deal(address(curationToken), bob, bobStakeAmount);

        vm.startPrank(bob);
        curationDetails.curationToken.approve(curationInstance, bobStakeAmount);

        vm.expectEmit(true, true, false, false, address(curationInstance));
        emit Staked(bob, bobStakeAmount);

        Curation(curationInstance).stake(bobStakeAmount);
        vm.stopPrank();

        assertEq(Curation(curationInstance).stakedAmounts(bob), bobStakeAmount);
    }

    function test_stakeTargetAmount() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, curationInstance, 170_000 ether);
        stake(alice, curationInstance, 230_000 ether);

        vm.recordLogs();

        stake(eve, curationInstance, 150_000 ether);

        // shouldnt transfer more then targetAmount
        assertEq(curationToken.balanceOf(eve), 50_000 ether);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 expectedSig = keccak256("PoolCreated(address)");

        // find if PoolCreated event was emitted
        (bool found, ) = findEvent(entries, expectedSig, curationInstance);

        assertEq(
            uint8(Curation(curationInstance).curationStatus()),
            uint8(CurationStatus.ENDED)
        );

        assertEq(found, true);
    }

    function test_canUnstake() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, curationInstance, 170_000 ether);

        vm.startPrank(bob);
        Curation(curationInstance).unstake(50_000 ether);

        vm.expectRevert(Curation__InsufficientBalance.selector);
        Curation(curationInstance).unstake(500_000 ether);

        vm.stopPrank();

        assertEq(Curation(curationInstance).stakedAmounts(bob), 120_000 ether);
    }

    function test_unstakeAfteTargetReached() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, curationInstance, TARGET_AMOUNT);

        vm.expectRevert(Curation__InvalidStatus.selector);

        vm.prank(bob);
        Curation(curationInstance).unstake(50_000 ether);
    }

    function test_claim() public {
        (
            address curationInstance,
            CurationDetails memory curationDetails
        ) = createSubmission(deployer);

        stake(bob, curationInstance, TARGET_AMOUNT / 2);
        stake(eve, curationInstance, TARGET_AMOUNT / 2);

        vm.prank(bob);
        Curation(curationInstance).claim();

        assertEq(
            curationDetails.newToken.balanceOf(bob),
            curationDetails.distributionAmount / 2
        );
    }

    function test_cantClaimIfCurationNotEnded() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, curationInstance, 100_000 ether);

        vm.expectRevert(Curation__InvalidStatus.selector);

        vm.prank(bob);
        Curation(curationInstance).claim();
    }

    function test_cantClaimIfDidntStake() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, curationInstance, 500_000 ether);

        vm.expectRevert(Curation__InsufficientBalance.selector);

        vm.prank(eve);
        Curation(curationInstance).claim();
    }

    function test_LiquidityLockedInPool() public {
        (address curationInstance, ) = createSubmission(deployer);

        stake(bob, address(curationInstance), TARGET_AMOUNT);
        assertEq(IERC721(baseSepoliapositionManager).balanceOf(deployer), 1);
    }
}
