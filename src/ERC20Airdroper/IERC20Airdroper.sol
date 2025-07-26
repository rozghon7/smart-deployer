// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title @title IERC20Airdroper - Interface for ERC20 token airdrop functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for ERC20 token airdrops.
interface IERC20Airdroper {
    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if tresuary doesn't approve enough tokens for ERC721Airdropper.
    error NotEnoughApprovedTokens();
    /// @dev Reverts if ERC20 transfer fails.
    error TransferToAddressFailed();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param amounts Amount of tokens distribution for every receiver.
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external;

    /// @notice Helper to encode constructor-style init data.
    /// @param _deployManager Address of the DeployManager.
    /// @param _tokenAddress Address of ERC20 token contract.
    /// @param _airdropAmount  Amount used to validate allowance.
    /// @param _treasury Address holding the tokens.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization bytes.
    function getInitData(
        address _deployManager,
        address _tokenAddress,
        uint256 _airdropAmount,
        address _treasury,
        address _owner
    ) external pure returns (bytes memory);
}
