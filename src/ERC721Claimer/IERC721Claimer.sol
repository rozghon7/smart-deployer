// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title IERC721Claimer - Interface for ERC721 NFT token claiming functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for claiming ERC721 tokens.
interface IERC721Claimer {
    /// @notice Emited when token claimed by a user.
    event NFTClaimed(address indexed claimer, uint256 indexed _tokenId, uint256 timestamp);
    /// @notice Emitted when NFTs are deposited into the contract.
    event DepositMade(address indexed sender, uint256[] _tokenIds, address indexed tokenAddress);

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
    /// @notice Reverts if the token ID is zero.
    error TokenIdMustBeGreaterThanZero();
    /// @notice Reverts if the token is not owned by the contract.
    error NFTNotOwnedByContract();
    /// @notice Reverts if the ID length is zero.
    error IdLengthMustBeGreaterThanZero();
    /// @notice Reverts if the NFTs are not approved for transfer.
    error NFTsNotApprovedForAll();

    /// @notice Allows a user to claim an NFT based on a Merkle proof.
    /// @param _tokenId The ID of the token to claim.
    /// @param proof The Merkle proof to verify the claim.
    function claim(uint256 _tokenId, bytes32[] calldata proof) external;

    /// @notice Checks if the user is eligible to claim an NFT based on a Merkle proof.
    /// @param _tokenId The ID of the token to claim.
    /// @param proof The Merkle proof to verify the claim.
    /// @return True if the user is eligible to claim, false otherwise.
    function airdropChecker(uint256 _tokenId, bytes32[] calldata proof) external view returns (bool);

    /// @notice Allows the owner to recover unclaimed NFTs after the claim period has expired.
    function recoverUnclaimed(uint256[] calldata _tokenIdsToRecover) external;

    /// @notice Allows the owner to deposit NFTs into the contract.
    function deposit(uint256[] calldata _tokenIds) external;

    /// @notice Returns the ABI-encoded initialization data for the contract.
    /// @param _deployManager Address of the deploy manager.
    /// @param _tokenAddress Address of the ERC721 token.
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
