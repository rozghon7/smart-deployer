// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IERC20Claimer - Interface for ERC20 token claiming functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for claiming ERC20 tokens.
interface IERC20Claimer {
    /// @notice Emited when tokens are claimed by a user.
    event TokensClaimed(address indexed claimer, uint256 indexed amount, uint256 timestamp);
    /// @notice Emited when tokens are deposited into the contract.
    event DepositMade(address indexed sender, uint256 amount, address indexed tokenAddress);

    /// @notice Reverts if the user tries to claim tokens that have already been claimed.
    error AlreadyClaimed();
    /// @notice Reverts if there are no tokens to claim for the user.
    error NothingToClaim();
    /// @notice Reverts if the transaction fails.
    error TransactionFailed();
    /// @notice Reverts if the claim time has passed.
    error TooLateForClaim();
    /// @notice Reverts if contracn have nothing to withdraw.
    error NothingToWithdraw();
    /// @notice Reverts if the claim time does not expire and the owner tries to recover unclaimed tokens.
    error ClaimTimeDoesNotExpired();
    /// @notice Reverts if deposit transfer fails.
    error DepositFailed();
    /// @notice Reverts if the amount to claim is zero.
    error AmountMustBeGreaterThanZero();
    /// @notice Reverts if there are not enough funds in the contract to fulfill the claim.
    error NotEnoughFundsInContract();

    /// @notice Allows a user to claim tokens based on a Merkle proof.
    /// @param _amount The amount of tokens to claim.
    /// @param proof The Merkle proof to verify the claim.
    function claim(uint256 _amount, bytes32[] calldata proof) external;

    /// @notice Checks if the user is eligible to claim tokens based on a Merkle proof.
    /// @param _amount The amount of tokens to check.
    /// @param proof The Merkle proof to verify the claim.
    /// @return True if the user is eligible to claim, false otherwise.
    function airdropChecker(uint256 _amount, bytes32[] calldata proof) external view returns (bool);

    /// @notice Allows the owner to recover unclaimed tokens after the claim period has expired.
    function recoverUnclaimed() external;

    /// @notice Allows the owner to deposit tokens into the contract.
    function deposit(uint256 _amount) external;

    /// @notice Returns the ABI-encoded initialization data for the contract.
    /// @param _deployManager Address of the deploy manager.
    /// @param _tokenAddress Address of the ERC20 token.
    /// @param _merkleRoot The Merkle root of the airdrop.
    /// @param _timeForClaim The time until which claims are allowed.
    /// @param _owner Address of the contract owner.
    /// @return ABI-encoded initialization data.
    function getInitData(
        address _deployManager,
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _timeForClaim,
        address _owner
    ) external pure returns (bytes memory);
}
