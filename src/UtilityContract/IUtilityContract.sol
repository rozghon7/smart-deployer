// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title IUtilityContract - Interface for utility contracts.
/// @author rozghon7.
/// @notice This interface defines the functions and events for utility contracts.
/// @dev Utility contracts should implement this interface to be compatible with the DeployManager.
interface IUtilityContract is IERC165 {
    /// @dev Reverts if the deploy manager is not set or is invalid.
    error DeployManagerCantBeZeroAddress();
    /// @dev Reverts if caller is not DeployManager.
    error NotDeployManager();
    /// @dev Reverts if validation failed.
    error FailedToDeployManager();
    /// @dev Reverts if the contract already initialized.
    error AlreadyInitialized();

    /// @notice Initializes the utility contract with the provided data.
    /// @param _initData The initialization data for the utility contract.
    /// @return True if the initialization was successful.
    /// @dev This function should be called by the DeployManager after deploying the contract.
    function initialize(bytes memory _initData) external returns (bool);

    /// @dev Returns DeployManager address.
    function getDeployManager() external view returns (address);
}
