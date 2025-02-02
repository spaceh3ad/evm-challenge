// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../../lib/Errors.sol";
import "../../lib/Structs.sol";
import "../../lib/Events.sol";
import {PoolHelper} from "../../lib/PoolHelper.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/**
 * @title Curation Contract
 * @author spaceh3ad
 * @notice This contract handles the staking process for token curation, sets up a Uniswap V3 pool
 *         when a target is reached, and enables users to claim new tokens based on their stake.
 * @dev Uses OpenZeppelin's Initializable for initialization process.
 */
contract Curation is Initializable {
    using SafeERC20 for IERC20;

    // -------------------------
    // Constants and State Variables
    // -------------------------

    /// @notice Uniswap V3 pool fee constant
    uint24 public constant POOL_FEE = 3000;

    /// @notice Address of the Uniswap NonfungiblePositionManager
    address public positionManager;

    /// @notice Configuration and details for the curation process
    CurationDetails public curationDetails;

    /// @notice Current status of the curation process
    CurationStatus public curationStatus;

    /// @notice Mapping to keep track of each user's staked token amount
    mapping(address => uint256) public stakedAmounts;

    // -------------------------
    // Modifiers
    // -------------------------

    /**
     * @notice Ensures that the curation contract is in the expected status.
     * @param _status The expected curation status.
     */
    modifier validateStatus(CurationStatus _status) {
        require(curationStatus == _status, Curation__InvalidStatus());
        _;
    }

    // -------------------------
    // External Functions
    // -------------------------

    /**
     * @notice Initializes the contract with curation details and the Uniswap position manager.
     * @dev This function can only be called once due to the `initializer` modifier.
     * @param _curationDetails Struct containing the curation configuration.
     * @param _positionManager Address of the Uniswap NonfungiblePositionManager.
     */
    function initialize(
        CurationDetails calldata _curationDetails,
        address _positionManager
    ) external initializer {
        curationDetails = _curationDetails;
        positionManager = _positionManager;
        curationStatus = CurationStatus.PENDING;
    }

    /**
     * @notice Stake tokens into the curation contract.
     * @dev Stakes tokens until the target amount is reached. Once the target is met,
     *      the curation status is updated to ENDED and a new Uniswap pool is created.
     * @param amount The amount of curation tokens to stake.
     */
    function stake(
        uint256 amount
    ) external validateStatus(CurationStatus.PENDING) {
        uint256 currentBalance = curationDetails.curationToken.balanceOf(
            address(this)
        );

        if (currentBalance + amount >= curationDetails.targetAmount) {
            amount = curationDetails.targetAmount - currentBalance;
            curationStatus = CurationStatus.ENDED;
        }

        curationDetails.curationToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        stakedAmounts[msg.sender] += amount;

        emit Staked(msg.sender, amount);

        if (curationStatus == CurationStatus.ENDED) {
            address pool = _setUpPool();
            emit PoolCreated(pool);
        }
    }

    /**
     * @notice Unstake tokens from the curation contract.
     * @dev Allows users to withdraw their staked tokens while the curation is pending.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(
        uint256 amount
    ) external validateStatus(CurationStatus.PENDING) {
        require(
            stakedAmounts[msg.sender] >= amount,
            Curation__InsufficientBalance()
        );
        stakedAmounts[msg.sender] -= amount;
        curationDetails.curationToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Claim new tokens after the curation has ended.
     * @dev The claimable amount is determined by the proportion of tokens staked by the user.
     *      This function is only callable when the curation status is ENDED.
     */
    function claim() external validateStatus(CurationStatus.ENDED) {
        require(stakedAmounts[msg.sender] > 0, Curation__InsufficientBalance());

        uint256 amount = (stakedAmounts[msg.sender] *
            curationDetails.distributionAmount) / curationDetails.targetAmount;
        stakedAmounts[msg.sender] = 0;
        curationDetails.newToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Returns the current curation details.
     * @return The curation details struct.
     */
    function getCurationDetails()
        external
        view
        returns (CurationDetails memory)
    {
        return curationDetails;
    }

    // -------------------------
    // Internal Functions
    // -------------------------

    /**
     * @notice Sets up a new Uniswap V3 pool and mints a liquidity position.
     * @dev This function is called internally once the curation target is reached.
     * @return pool The address of the newly created Uniswap V3 pool.
     */
    function _setUpPool() internal returns (address pool) {
        (address token0, address token1) = PoolHelper.sortTokens(
            address(curationDetails.newToken),
            address(curationDetails.curationToken)
        );

        uint160 sqrtPriceX96 = PoolHelper.getSqrtPriceX96(
            curationDetails.targetAmount,
            curationDetails.liquidityAmount
        );

        pool = PoolHelper.initPool(
            token0,
            token1,
            POOL_FEE,
            sqrtPriceX96,
            INonfungiblePositionManager(positionManager)
        );

        IERC20(token0).approve(address(positionManager), type(uint256).max);
        IERC20(token1).approve(address(positionManager), type(uint256).max);

        INonfungiblePositionManager(positionManager).mint(
            PoolHelper.getMintParams(
                IUniswapV3Pool(pool),
                curationDetails.targetAmount,
                curationDetails.liquidityAmount,
                curationDetails.creator
            )
        );
    }
}
