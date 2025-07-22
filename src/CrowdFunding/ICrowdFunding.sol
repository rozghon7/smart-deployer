//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title ICrowdFunding - Interface for crowdfunding contract functionality.
/// @author rozghon7.
/// @notice Interface for a crowdfunding contract supporting contributions, refunds, and vesting-based payouts.
interface ICrowdFunding {
    /// @notice Emitted when a contribution is received.
    event ContributionReceived(address indexed _user, uint256 _amount, uint256 _timestamp);
    /// @notice Emitted when vesting starts.
    event VestingStarted(address indexed _vestingContractAddress, uint256 _timestamp);
    /// @notice Emitted when a refund is processed.
    event RefundProcessed(address indexed _user, uint256 _amount, uint256 _timestamp);
    /// @notice Emitted when the fundraiser withdraws funds from vesting.
    event FundsWithdrawnFromVesting(address indexed _fundraiser, uint256 _timestamp);

    /// @dev Reverts if the contribution value is invalid.
    error InvalidValue();
    /// @dev Reverts if trying to refund after the pool goal is reached.
    error PoolHasReachedAndYouCantRefund();
    /// @dev Reverts if user has nothing to refund.
    error NothingToRefund();
    /// @dev Reverts if refund amount exceeds user's balance.
    error AmountTooHigh();
    /// @dev Reverts if pool already reached.
    error PoolHasReached();
    /// @dev Reverts if ETH transfer to vesting failed.
    error TransactionFailed();
    /// @dev Reverts if caller is not the fundraiser.
    error OnlyFundraiserAllowed();
    /// @dev Reverts if vesting has not started.
    error VestingNotStarted();

    /// @notice Allows a user to contribute to the fundraising pool.
    /// @dev Reverts if pool already reached or goal would be exceeded.
    function contribute() external payable;

    /// @notice Allows a contributor to request a refund before pool is full.
    /// @param _value Amount to refund.
    function refund(uint256 _value) external;

    /// @notice Allows the fundraiser to withdraw vested tokens.
    function withdraw() external;

    /// @notice Encodes initialization parameters to bytes.
    /// @param _deployManager Address of DeployManager.
    /// @param _goal Target amount to reach.
    /// @param _fundraiser Address who receives funds via vesting.
    /// @param _vestingTime Duration of the vesting schedule.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization payload.
    function getInitData(
        address _deployManager,
        uint256 _goal,
        address _fundraiser,
        uint64 _vestingTime,
        address _owner
    ) external pure returns (bytes memory);
}
