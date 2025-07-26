// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title IERC721Airdroper - Interface for ERC721 token airdrop functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for ERC721 token airdrops.
interface IERC721Airdroper {
    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if treasury doesn't approve tokens for ERC721Airdropper.
    error NeedToApproveTokens();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param tokenIds The tokens IDs for distribution.
    function airdrop(address[] calldata receivers, uint256[] calldata tokenIds) external;

    /// @notice Helper to encode constructor-style init data.
    /// @param _deployManager Address of the DeployManager.
    /// @param _token Address of ERC721 token contract.
    /// @param _treasury Address holding the tokens.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization bytes.
    function getInitData(address _deployManager, address _token, address _treasury, address _owner)
        external
        pure
        returns (bytes memory);
}
