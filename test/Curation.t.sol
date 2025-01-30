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

        stake(eve, curationInstance, 100_000 ether);

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
}
