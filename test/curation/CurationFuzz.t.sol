// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../Fixture.sol";

contract CurationFuzzTest is Fixture {
    MockERC20 newToken;
    Curation curationInstance;

    function setUp() public override {
        super.setUp();

        newToken = MockERC20(
            createNewToken(deployer, DISTRIBUTION_AMOUNT + LIQUIDITY_AMOUNT)
        );

        CurationDetails memory _curationDetails = createCurationDetails(
            address(newToken),
            DISTRIBUTION_AMOUNT,
            TARGET_AMOUNT,
            LIQUIDITY_AMOUNT,
            deployer
        );

        vm.prank(deployer);
        newToken.approve(address(launchFactory), type(uint256).max);

        curationInstance = Curation(createSubmission(_curationDetails));
    }

    /// @notice Fuzz test for `stake`
    /// We fuzz with arbitrary stake amounts. If a stake would bring the total balance
    /// over the target, then the function should adjust the amount and trigger ENDED.
    /// Also the staked amount should always be accounted for smart contract
    function testFuzzStake(uint256 stakeAmount) public {
        stakeAmount = bound(stakeAmount, 100_000 ether, 500_000 ether);
        uint256 contractBalanceBefore = curationToken.balanceOf(
            address(curationInstance)
        );

        stake(bob, address(curationInstance), stakeAmount);

        uint256 contractBalanceAfter = curationToken.balanceOf(
            address(curationInstance)
        );
        uint256 staked = curationInstance.stakedAmounts(bob);

        if (stakeAmount < TARGET_AMOUNT) {
            assertEq(contractBalanceAfter - contractBalanceBefore, staked);
            assertEq(
                uint8(curationInstance.curationStatus()),
                uint8(CurationStatus.PENDING)
            );
        } else {
            assertEq(
                uint8(curationInstance.curationStatus()),
                uint8(CurationStatus.ENDED)
            );
        }
    }

    /// @notice Fuzz test for `unstake`
    /// Stake some tokens then unstake an amount that is at most what was staked.
    function testFuzzUnstake(
        uint256 stakeAmount,
        uint256 unstakeAmount
    ) public {
        stakeAmount = bound(stakeAmount, 1, TARGET_AMOUNT - 1); // check values lower then TARGET
        unstakeAmount = bound(unstakeAmount, 1, stakeAmount);
        stake(bob, address(curationInstance), stakeAmount);
        uint256 stakedBefore = curationInstance.stakedAmounts(bob);

        vm.prank(bob);
        curationInstance.unstake(unstakeAmount);
        uint256 stakedAfter = curationInstance.stakedAmounts(bob);

        assertEq(
            curationToken.balanceOf(address(curationInstance)),
            curationInstance.stakedAmounts(bob)
        );
        assertEq(stakedBefore - stakedAfter, unstakeAmount);
        vm.stopPrank();
    }
}
