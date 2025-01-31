// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Fixture.sol";

contract CurationTest is Fixture {
    address alice;
    address eve;

    function setUp() public override {
        super.setUp();

        alice = makeAddr("alice");
        eve = makeAddr("eve");

        vm.label(alice, "alice");
        vm.label(eve, "eve");
    }

    function test_stake() public {
        vm.startPrank(deployer);

        (
            address curationInstance,
            CurationDetails memory curationDetails
        ) = createSubmission(deployer);

        vm.stopPrank();

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
        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

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
        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

        stake(bob, curationInstance, 170_000 ether);

        vm.startPrank(bob);
        Curation(curationInstance).unstake(50_000 ether);

        vm.expectRevert(Curation__InsufficientBalance.selector);
        Curation(curationInstance).unstake(500_000 ether); // cant unstake more then staked

        vm.stopPrank();

        assertEq(Curation(curationInstance).stakedAmounts(bob), 120_000 ether);
    }

    function test_unstakeAfterCurationEnded() public {
        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

        stake(bob, curationInstance, 500_000 ether);

        vm.expectRevert(Curation__InvalidStatus.selector);

        vm.prank(bob);
        Curation(curationInstance).unstake(50_000 ether);
    }

    function test_claim() public {
        vm.startPrank(deployer);
        (
            address curationInstance,
            CurationDetails memory curationDetails
        ) = createSubmission(deployer);
        vm.stopPrank();

        stake(bob, curationInstance, 500_000 ether);

        vm.prank(bob);
        Curation(curationInstance).claim();

        assertGt(curationDetails.newToken.balanceOf(bob), 0);
    }

    function test_cantClaimIfCurationNotEnded() public {
        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

        stake(bob, curationInstance, 100_000 ether);

        vm.expectRevert(Curation__InvalidStatus.selector);

        vm.prank(bob);
        Curation(curationInstance).claim();
    }

    function test_cantClaimIfDidntStake() public {
        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

        stake(bob, curationInstance, 500_000 ether);

        vm.expectRevert(Curation__InsufficientBalance.selector);

        vm.prank(eve);
        Curation(curationInstance).claim();
    }
}
