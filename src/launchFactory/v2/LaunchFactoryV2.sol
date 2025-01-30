// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../../lib/Structs.sol";
import "../../lib/Errors.sol";
import "../../lib/Events.sol";

import {Curation} from "../../curation/v1/Curation.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:oz-upgrades-from LaunchFactory
contract LaunchFactoryV2 is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Clones for address;

    address public curationImplementation;
    address public positionManager;
    address[] public curations;

    modifier _validateSubmission(CurationDetails calldata _curationDetails) {
        require(
            address(_curationDetails.curationToken) != address(0) &&
                address(_curationDetails.newToken) != address(0) &&
                _curationDetails.distributionAmount > 0 &&
                _curationDetails.targetAmount > 0,
            TokenLauncher__InvalidSubmissionParams()
        );
        _;
    }

    function initialize(
        address initialOwner,
        address _curationImplementation,
        address _positionManager
    ) public initializer {
        __Ownable_init(initialOwner);
        curationImplementation = _curationImplementation;
        positionManager = _positionManager;
    }

    function createSubmission(
        CurationDetails calldata _curationDetails
    ) public _validateSubmission(_curationDetails) returns (address clone) {
        uint256 totalAmount = _curationDetails.distributionAmount +
            _curationDetails.liquidityAmount;

        clone = curationImplementation.clone();

        _curationDetails.newToken.safeTransferFrom(
            msg.sender,
            clone,
            totalAmount
        );

        (bool success, ) = clone.call(
            abi.encodeWithSignature(
                "initialize((address,address,uint256,uint256,uint256,address),address)",
                _curationDetails,
                positionManager
            )
        );
        require(success, TokenLauncher__CurationInitFailed());

        curations.push(clone);

        emit SubmissionCreated(clone);
    }

    function getCurationsData()
        external
        view
        returns (FullCurationInfo[] memory)
    {
        FullCurationInfo[] memory curationInfo = new FullCurationInfo[](
            curations.length
        );

        for (uint256 i = 0; i < curations.length; i++) {
            address _curation = curations[i];

            CurationDetails memory details = Curation(_curation)
                .getCurationDetails();

            curationInfo[i] = FullCurationInfo({
                curationAddress: _curation,
                curationDetails: details,
                curationStatus: Curation(_curation).curationStatus()
            });
        }
        return curationInfo;
    }

    function upgradeImplementation(
        address _newImplementation
    ) external onlyOwner {
        curationImplementation = _newImplementation;
        emit ImplementationUpgraded(_newImplementation);
    }
}
