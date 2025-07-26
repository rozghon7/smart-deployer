// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title IERC1155Airdroper - Interface for ERC1155 token airdrop functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for ERC1155 token airdrops.
interface IERC1155Airdroper {
    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if treasury doesn't approve tokens for ERC1155Airdropper.
    error NeedToApproveTokens();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param amounts Amount of tokens distribution for every receiver.
    /// @param tokenId The tokens IDs for distribution.
    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenId) external;

    /// @notice Helper to encode constructor-style init data.
    /// @param _deployManager Address of the DeployManager.
    /// @param _tokenAddress Address of ERC1155 token contract.
    /// @param _treasury Address holding the tokens.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization bytes.
    function getInitData(address _deployManager, address _tokenAddress, address _treasury, address _owner)
        external
        pure
        returns (bytes memory);
}
