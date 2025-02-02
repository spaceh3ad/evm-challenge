// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../../lib/Structs.sol";
import "../../lib/Errors.sol";
import "../../lib/Events.sol";
import {Curation} from "../../curation/v1/Curation.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title LaunchFactory
 * @author spaceh3ad
 * @notice Factory contract for creating curation submissions using the clone (minimal proxy) pattern.
 * @dev The contract is upgradeable and uses OwnableUpgradeable for access control.
 *      New curation contracts are deployed as clones of a given implementation and require initialization.
 */
contract LaunchFactory is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Clones for address;

    // -------------------------
    // State Variables
    // -------------------------

    /// @notice Address of the curation implementation used as the template for cloning.
    address public curationImplementation;

    /// @notice Address of the uniswap v3 position manager contract.
    address public positionManager;

    /// @notice Array of addresses of all created curation clones.
    address[] public curations;

    // -------------------------
    // External Functions
    // -------------------------

    /**
     * @notice Initializes the LaunchFactory contract.
     * @dev This function replaces a constructor for upgradeable contracts deployed via proxies/clones.
     * @param initialOwner The initial owner of the contract.
     * @param _curationImplementation The address of the curation implementation contract.
     * @param _positionManager The address of the position manager contract.
     */
    function initialize(
        address initialOwner,
        address _curationImplementation,
        address _positionManager
    ) external initializer {
        __Ownable_init(initialOwner);
        curationImplementation = _curationImplementation;
        positionManager = _positionManager;
    }

    /**
     * @notice Creates a new curation submission by deploying a clone of the curation implementation.
     * @dev Transfers the required tokens to the new clone and initializes it.
     *      Reverts if submission parameters are invalid or if the initialization call fails.
     * @param _curationDetails The curation details required for the submission.
     * @return clone The address of the newly created curation clone.
     */
    function createSubmission(
        CurationDetails calldata _curationDetails
    ) external returns (address clone) {
        require(
            address(_curationDetails.curationToken) != address(0) &&
                address(_curationDetails.newToken) != address(0) &&
                _curationDetails.distributionAmount > 0 &&
                _curationDetails.targetAmount > 0 &&
                _curationDetails.liquidityAmount > 0,
            TokenLauncher__InvalidSubmissionParams()
        );

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

    /**
     * @notice Upgrades the curation implementation address used for deploying new clones.
     * @dev Only callable by the contract owner.
     * @param _newImplementation The new address for the curation implementation.
     */
    function upgradeImplementation(
        address _newImplementation
    ) external onlyOwner {
        curationImplementation = _newImplementation;
        emit ImplementationUpgraded(_newImplementation);
    }

    /**
     * @notice Retrieves detailed information for all curation submissions.
     * @dev Iterates through the stored curation addresses and collects their corresponding details and status.
     * @return An array of FullCurationInfo structs, each containing the curation contract address, its details, and current status.
     */
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
}
