// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./Fixture.sol";

contract LaunchFactoryTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function test_createSubmision() public {
        vm.expectEmit(false, false, false, false, address(launchFactory));
        emit SubmissionCreated(address(curation));

        createSubmission();
    }

    function test_upgradeFactory() public {
        address _proxy = address(launchFactory);
        string memory _newImplementationContractName = "LaunchFactoryV2.sol";
        bytes memory _data = hex"";
        upgradeFactory(_proxy, _newImplementationContractName, _data);

        address _curation = createSubmission();

        LaunchFactoryV2(_proxy).curations(0);
        assertEq(LaunchFactoryV2(_proxy).curations(0), _curation);
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

        vm.prank(deployer);
        address curationInstance = launchFactory.createSubmission(
            getCurationDetails()
        );

        CurationV2(curationInstance).setV2();
        assertEq(CurationV2(curationInstance).isV2(), true);
    }
}
