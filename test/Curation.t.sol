// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Fixture.sol";

contract CurationTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_stake() public {
        vm.startPrank(deployer);
        CurationDetails memory curationDetails = getSampleCurationDetails(
            deployer
        );

        address curationInstance = launchFactory.createSubmission(
            curationDetails
        );
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
}
