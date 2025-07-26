// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title @title IERC1155Claimer - Interface for ERC1155 NFT token claiming functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for claiming ERC1155 tokens.
interface IERC1155Claimer {
    /// @notice Emited when token claimed by a user.
    event TokensClaimed(address indexed claimer, uint256[] _tokenIds, uint256[] amounts, uint256 timestamp);
    /// @notice Emitted when NFTs are deposited into the contract.
    event DepositMade(address indexed sender, uint256[] _tokenIds, uint256[] _amounts, address indexed tokenAddress);

    /// @notice Reverts if the user tries to claim tokens that have already been claimed.
    error AlreadyClaimed();
    /// @notice Reverts if there are no tokens to claim for the user.
    error NothingToClaim();
    /// @notice Reverts if the claim time has passed.
    error TooLateForClaim();
    /// @notice Reverts if the claim time does not expire and the owner tries to recover unclaimed tokens.
    error ClaimTimeDoesNotExpired();
    /// @notice Reverts if the token ID is zero.
    error TokenIdMustBeGreaterThanZero();
    /// @notice Reverts if the ID length is zero.
    error IdLengthMustBeGreaterThanZero();
    /// @notice Reverts if the length of the token IDs and amounts do not match.
    error LengthSizesMismatch();
    /// @notice Reverts if the contract does not have enough funds to transfer.
    error NotEnoughFundsInContract();
    /// @notice Reverts if the caller does not have enough funds to transfer.
    error NotEnoughFunds();
    /// @notice Reverts if the amount is zero.
    error AmountCanNotBeZero();
    /// @notice Reverts if the token is not approved for transfer.
    error NotApprovedForAll();

    /// @notice Allows a user to claim an NFT based on a Merkle proof.
    /// @param tokenIds The ID of the token to claim.
    /// @param amount The amounts of the items to claim.
    /// @param proof The Merkle proof to verify the claim.
    function claim(uint256[] calldata tokenIds, uint256[] calldata amount, bytes32[] calldata proof) external;

    /// @notice Checks if the user is eligible to claim an NFT based on a Merkle proof.
    /// @param tokenIds The IDs of the items to check.
    /// @param amount The amount of tokens to claim.
    /// @param proof The Merkle proof to verify the claim.
    /// @return True if the user is eligible to claim, false otherwise.
    function airdropChecker(uint256[] calldata tokenIds, uint256[] calldata amount, bytes32[] calldata proof)
        external
        view
        returns (bool);

    /// @notice Allows the owner to recover unclaimed NFTs after the claim period has expired.
    /// @param _tokenIdsToRecover The IDs of the tokens to recover.
    /// @param _amountsToRecover The amounts of the tokens to recover.
    function recoverUnclaimed(uint256[] calldata _tokenIdsToRecover, uint256[] calldata _amountsToRecover) external;

    /// @notice Allows the owner to deposit NFTs into the contract.
    /// @param _tokenIds The IDs of the tokens to deposit.
    /// @param _amounts The amounts of the tokens to deposit.
    function deposit(uint256[] calldata _tokenIds, uint256[] calldata _amounts) external;

    /// @notice Returns the ABI-encoded initialization data for the contract.
    /// @param _deployManager Address of the deploy manager.
    /// @param _tokenAddress Address of the ERC1155 token.
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
