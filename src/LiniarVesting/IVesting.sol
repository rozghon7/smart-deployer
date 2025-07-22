// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title IVesting - Interface for token vesting functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for vesting schedules.
interface IVesting {
    /// @notice Emits when a new vesting schedule is created.
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 creationTime);
    /// @notice Emits when tokens are withdrawn by the owner.
    event TokensWithdrawn(address indexed to, uint256 amount);
    /// @notice Emits when tokens are claimed by a beneficiary.
    event Claim(address indexed beneficiary, uint256 amount, uint256 timestamp);

    /// @notice Vesting schedule details for a beneficiary.
    /// @param totalAmount Total tokens allocated for vesting.
    /// @param startTime Timestamp when vesting starts.
    /// @param cliff Time period before tokens start unlocking (in seconds).
    /// @param duration Total time over which tokens are unlocked (in seconds).
    /// @param claimed Amount of tokens already claimed by the user.
    /// @param lastClaimTime Timestamp of the most recent claim.
    /// @param claimCooldown Required time gap between consecutive claims (in seconds).
    /// @param minClaimAmount Minimum number of tokens that can be claimed at once.
    /// @param created True if the vesting schedule has been initialized.
    struct VestingInfo {
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
        uint256 claimed;
        uint256 lastClaimTime;
        uint256 claimCooldown;
        uint256 minClaimAmount;
        bool created;
    }

    /// @notice Parameters for creating a new vesting schedule.
    /// @param beneficiary Address of the beneficiary.
    /// @param totalAmount Total tokens allocated for vesting.
    /// @param startTime Timestamp when vesting starts.
    /// @param cliff Cliff period (in seconds).
    /// @param duration Duration of the vesting (in seconds).
    /// @param claimCooldown Interval between claims.
    /// @param minClaimAmount Minimum claimable token amount.
    struct VestingParameters {
        address beneficiary;
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliff;
        uint256 duration;
        uint256 claimCooldown;
        uint256 minClaimAmount;
    }

    /// @notice Reverts if the vesting schedule does not exist for the beneficiary.
    error VestingNotFound();
    /// @notice Reverts if the claim is not yet available.
    /// @param _timestamp Current block timestamp.
    /// @param _availableFrom Timestamp when the claim becomes available (in seconds).
    error ClaimNotAvailable(uint256 _timestamp, uint256 _availableFrom);
    /// @notice Reverts if there are no tokens available to claim.
    error NothingToClaim();
    /// @notice Reverts if the contract does not have enough tokens to allocate.
    /// @param _availableBalance Number of tokens currently available in the contract.
    /// @param _totalAmount Number of tokens required for vesting.
    error InsufficientBalance(uint256 _availableBalance, uint256 _totalAmount);
    /// @notice Reverts if a vesting schedule already exists for the beneficiary.
    error VestingAlreadyExists();
    /// @notice Reverts if the specified amount is zero.
    error AmountCantBeZero();
    /// @notice Reverts if the vesting start time is not in the future.
    /// @param _startTime The specified start time (in seconds).
    /// @param _timestamp The current block timestamp.
    error StartTimeShouldBeFuture(uint256 _startTime, uint256 _timestamp);
    /// @notice Reverts if the vesting duration is zero.
    error DurationCantBeZero();
    /// @notice Reverts if the claim cooldown period is longer than the vesting duration
    /// @param _claimCooldown Cooldown between claims (in seconds).
    /// @param _duration Duration time (in seconds).
    error CooldownCantBeLongerThanDuration(uint256 _claimCooldown, uint256 _duration);
    /// @notice Reverts if the beneficiary address is invalid.
    error InvalidBeneficiary();
    /// @notice Reverts if the claimable amount is less than the minimum claim amount.
    /// @param _claimable The actual claimable amount.
    /// @param _minToClaim The minimum claimable amount.
    error BelowMinimalClaimAmount(uint256 _claimable, uint256 _minToClaim);
    /// @notice Reverts if the required cooldown period between claims has not passed.
    /// @param _timestamp The current block timestamp.
    /// @param _lastClaimTime The timestamp of the last claim.
    error CooldownNotPassed(uint256 _timestamp, uint256 _lastClaimTime);
    /// @notice Reverts if there are no tokens available to withdraw.
    error NothingToWithdraw();

    /// @notice Claims all tokens currently available for the caller according to their vesting schedule.
    function claim() external;

    /// @notice Returns the total amount of tokens vested for a beneficiary at the current time.
    /// @param _claimer Address of the beneficiary.
    /// @return Amount of tokens vested.
    function vestedAmount(address _claimer) external view returns (uint256);

    /// @notice Returns the amount of tokens that can currently be claimed by a beneficiary.
    /// @param _claimer Address of the beneficiary.
    /// @return Amount of tokens claimable.
    function claimableAmount(address _claimer) external view returns (uint256);

    /// @notice Creates a new vesting schedule for a beneficiary.
    /// @param parametrs Struct containing the parameters for the new vesting schedule.
    function startVesting(VestingParameters calldata parametrs) external;

    /// @notice Withdraws all unallocated tokens from the contract to the specified address.
    /// @param _to Address to receive the withdrawn tokens.
    function withdrawUnallocated(address _to) external;

    /// @notice Returns the ABI-encoded initialization data for the contract.
    /// @param _deployManager Address of the deploy manager.
    /// @param _token Address of the ERC20 token.
    /// @param _owner Address of the contract owner.
    /// @return ABI-encoded initialization data.
    function getInitData(address _deployManager, address _token, address _owner) external pure returns (bytes memory);
}
