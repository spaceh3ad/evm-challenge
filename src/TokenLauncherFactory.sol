// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./lib/Structs.sol";
import "./lib/Errors.sol";

import {Curation} from "./Curation.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenLauncherFactory is Ownable {
    using Clones for address;

    event ImplementationUpgraded(address indexed newImplementation);
    event SubmissionCreated(address indexed token);

    address public curationImplementation;

    modifier _validateSubmission(CurationDetails calldata curationDetails) {
        require(
            address(curationDetails.curationToken) != address(0) &&
                address(curationDetails.newToken) != address(0) &&
                curationDetails.distributionAmount > 0 &&
                curationDetails.targetAmount > 0,
            TokenLauncher__InvalidSubmissionParams()
        );
        _;
    }

    constructor(address _curationImplementation) Ownable(msg.sender) {
        curationImplementation = _curationImplementation;
    }

    function createSubmission(
        CurationDetails calldata curationDetails
    ) public _validateSubmission(curationDetails) returns (address clone) {
        clone = curationImplementation.clone();

        emit SubmissionCreated(clone);

        (bool success, ) = clone.call(
            abi.encodeWithSignature(
                "initialize((address,address,uint256,uin256))",
                curationDetails
            )
        );
        require(success, TokenLauncher__CurationInitFailed());
    }

    function upgradeImplementation(
        address _newImplementation
    ) external onlyOwner {
        curationImplementation = _newImplementation;
        emit ImplementationUpgraded(_newImplementation);
    }
}
