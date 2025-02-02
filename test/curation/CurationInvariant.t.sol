// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../Fixture.sol";

contract Handler is Test {
    Curation curation;

    uint256 MIN_STAKE = 100_000 ether;
    uint256 MAX_STAKE = 400_000 ether;

    constructor(Curation _curation) {
        curation = _curation;
    }

    function stake(address _user, uint256 _amount) external {
        _amount = bound(_amount, MIN_STAKE, MAX_STAKE);
        (IERC20 curationToken, , , , , ) = curation.curationDetails();
        deal(address(curationToken), _user, _amount);
        vm.startPrank(_user);
        curationToken.approve(address(curation), _amount);
        curation.stake(_amount);
        vm.stopPrank();
    }

    function unstake(address _user, uint256 _amount) external {
        vm.prank(_user);
        curation.unstake(_amount);
        vm.stopPrank();
    }
}

contract CurationInvariantTest is Fixture {
    MockERC20 newToken;
    Curation curationInstance;
    Handler handler;

    function setUp() public override {
        super.setUp();
        (address _curationInstance, ) = createSubmission(deployer);
        curationInstance = Curation(_curationInstance);

        handler = new Handler(curationInstance);
        targetContract(address(handler));

        vm.recordLogs();
    }

    /// @notice Invariant: If the curation has ended then the pool must have been created.
    /// In our implementation the final stake is adjusted so that the contract's balance equals targetAmount.
    /// Thus, when curationStatus == ENDED the contract's balance of the staking token must equal the target.
    function invariant_poolCreatedWhenEnded() public {
        Vm.Log[] memory entries = vm.getRecordedLogs();

        if (
            uint(curationInstance.curationStatus()) ==
            uint(CurationStatus.ENDED)
        ) {
            bytes32 expectedSig = keccak256("PoolCreated(address)");

            // find if PoolCreated event was emitted
            bool found = findEvent(
                entries,
                expectedSig,
                address(curationInstance)
            );

            assertEq(found, true);
        }
    }

    // should not be possible to unstake more then staked
    function invariant_shouldHavePendingStatusIfNotStakedTargetAmount() public {
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 expectedSig = keccak256("PoolCreated(address)");

        // find if PoolCreated event was emitted
        bool found = findEvent(entries, expectedSig, address(curationInstance));

        (, , , uint256 targetAmount, , ) = curationInstance.curationDetails();
        if (
            curationToken.balanceOf(address(curationInstance)) < targetAmount &&
            !found
        ) {
            assertEq(
                uint8(curationInstance.curationStatus()),
                uint8(CurationStatus.PENDING)
            );
        }
    }
}
