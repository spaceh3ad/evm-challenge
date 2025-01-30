// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "./lib/Structs.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol";

import {Curation} from "./Curation.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {console} from "forge-std/console.sol";

contract LaunchFactory is Ownable {
    using SafeERC20 for IERC20;
    using Clones for address;

    address public curationImplementation;
    address public immutable i_positionManager;

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

    constructor(
        address _curationImplementation,
        address _positionManager
    ) Ownable(msg.sender) {
        curationImplementation = _curationImplementation;
        i_positionManager = _positionManager;
    }

    function createSubmission(
        CurationDetails calldata curationDetails
    ) public _validateSubmission(curationDetails) returns (address clone) {
        clone = curationImplementation.clone();

        (bool success, ) = clone.call(
            abi.encodeWithSignature(
                "initialize((address,address,uint256,uint256,uint256),address)",
                curationDetails,
                i_positionManager
            )
        );
        require(success, TokenLauncher__CurationInitFailed());

        curationDetails.curationToken.safeTransferFrom(
            msg.sender,
            clone,
            curationDetails.distributionAmount
        );

        emit SubmissionCreated(clone);
    }

    function upgradeImplementation(
        address _newImplementation
    ) external onlyOwner {
        curationImplementation = _newImplementation;
        emit ImplementationUpgraded(_newImplementation);
    }
}
