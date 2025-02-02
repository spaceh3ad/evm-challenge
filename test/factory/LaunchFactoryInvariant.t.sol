// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../Fixture.sol";

contract LaunchFactoryHandler is Test {
    LaunchFactory factory;
    address[] public curationsCreated;
    address public currentImpl;

    constructor(LaunchFactory _factory) {
        factory = _factory;
        currentImpl = _factory.curationImplementation();
    }

    function upgradeImplementation() public {
        if (msg.sender == factory.owner()) {
            currentImpl = address(new Curation());
            factory.upgradeImplementation(currentImpl);
        }
    }
}

contract LaunchFactoryInvariantTest is Fixture {
    LaunchFactoryHandler handler;

    function setUp() public override {
        super.setUp();
        handler = new LaunchFactoryHandler(launchFactory);
        targetContract(address(handler));
    }

    function invariant_implementationIntegrity() public {
        assertTrue(launchFactory.curationImplementation().code.length > 0);
        assertEq(launchFactory.curationImplementation(), handler.currentImpl());
    }
}
