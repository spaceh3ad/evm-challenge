// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Fixture.sol";

contract LaunchFactoryTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_createSubmision() public {
        vm.startPrank(deployer);
        CurationDetails memory curationDetails = getSampleCurationDetails(
            deployer
        );

        vm.expectEmit(false, false, false, false, address(launchFactory));
        // we dont check curation address
        emit SubmissionCreated(address(0));

        launchFactory.createSubmission(curationDetails);
        vm.stopPrank();
    }

    function test_upgradeFactory() public {
        address _proxy = address(launchFactory);
        string memory _newImplementationContractName = "LaunchFactoryV2.sol";
        bytes memory _data = hex"";
        upgradeFactory(_proxy, _newImplementationContractName, _data);

        vm.startPrank(deployer);
        (address curationInstance, ) = createSubmission(deployer);
        vm.stopPrank();

        LaunchFactoryV2(_proxy).curations(0);
        assertEq(LaunchFactoryV2(_proxy).curations(0), curationInstance);
    }

    function test_upgradeCurationImplementation() public {
        address newCurationImplementation = address(new CurationV2());

        vm.expectEmit(true, false, false, false, address(launchFactory));
        emit ImplementationUpgraded(newCurationImplementation);

        vm.prank(deployer);
        launchFactory.upgradeImplementation(newCurationImplementation);
        assertEq(
            launchFactory.curationImplementation(),
            newCurationImplementation
        );
    }

    function test_newFeatureInCurationV2() public {
        // resue test case to upgrade curation implementation
        test_upgradeCurationImplementation();

        vm.startPrank(deployer);
        address curationInstance = launchFactory.createSubmission(
            getSampleCurationDetails(deployer)
        );
        vm.stopPrank();

        CurationV2(curationInstance).setV2();
        assertEq(CurationV2(curationInstance).isV2(), true);
    }
}
