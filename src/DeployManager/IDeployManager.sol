// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @title IDeployManager - Factory for utility contracts
/// @author rozghon7
/// @notice This interface defines the functions, errors and events for the DeployManager contract.
interface IDeployManager is IERC165 {
    /// @dev Stores registered contracts information.
    struct ContractInfo {
        uint256 fee;
        bool isActive;
        uint256 registeredAt;
    }

    /// @dev Reverts if the contract is not active.
    error ContractDoesNotActive();
    /// @dev Not enough funds to deploy the contract.
    error NotEnoughFunds();
    /// @dev Reverts if the contract is not registered
    error ContractDoesNotRegistered();
    /// @dev Reverts if the initialize() function fails.
    error InitializationFailed();
    /// @dev Reverts when owner tries to add a contract that is already registered.
    error ContractAlreadyRegistered();
    /// @dev Reverts if the contract is not a utility contract.
    error ContractIsNotUtilityContract();
    /// @dev Reverts if the transaction fails.
    error TransactionFailed();

    /// @notice Emitted when a new utility contract template is registered.
    /// @param _contractAddress Address of the registered utility contract template.
    /// @param _fee Fee (in wei) required to deploy a clone of this contract.
    /// @param _isActive Whether the contract is active and deployable.
    /// @param _timestamp Timestamp when the contract was added.
    event NewContractAdded(address indexed _contractAddress, uint256 _fee, bool _isActive, uint256 _timestamp);

    /// @notice Emitted when contract deployment fee is updated.
    /// @param _contractAddress Address of the registered utility contract.
    /// @param _oldFee Fee (in wei) required to deploy a contract before update.
    /// @param _newFee Fee (in wei) required to deploy a contract after update.
    /// @param _timestamp Timestamp when contract fee was updated.
    event ContractFeeUpdated(address indexed _contractAddress, uint256 _oldFee, uint256 _newFee, uint256 _timestamp);

    /// @notice Emitted when contract status updated.
    /// @param _contractAddress Address of the contract, which status has updated.
    /// @param _isActive Current status of the contract. Status is true if the contract can be deployed.
    /// @param _timestamp Timestamp when contract status was updated.
    event ContractStatusUpdated(address indexed _contractAddress, bool _isActive, uint256 _timestamp);

    /// @notice Emitted when user deployed a new utility contract.
    /// @param _deployer Address of user, who initiated deployment.
    /// @param _contractAddress Address of the utility contract, which has deployed by user.
    /// @param _fee Fee (in wei) that user paid for deployment.
    /// @param _timestamp Timestamp when user made a deploy.
    event NewDeployment(address indexed _deployer, address indexed _contractAddress, uint256 _fee, uint256 _timestamp);

    /// @notice Deploys a new utility contract.
    /// @param _utilityContract The address of the registered utility contract.
    /// @param _initData The initialization data for the utility contract.
    /// @return The address of the deployed utility contract.
    /// @dev Emits NewDeployment event.
    function deploy(address _utilityContract, bytes calldata _initData) external payable returns (address);

    /// @notice Registered a new utility contract.
    /// @param _contractAddress The address of the utility contract template.
    /// @param _fee Fee (in wei) required for a contract deployment.
    /// @param _isActive Status is true if the contract can be deployed immediately.
    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external;

    /// @notice Update fee of registred utility contract.
    /// @param _contractAddress The address of the utility contract template.
    /// @param _newFee Fee (in wei) required to deploy a contract after update.
    function updateFee(address _contractAddress, uint256 _newFee) external;

    /// @notice Update status of registered utility contract to false (inactive).
    /// @param _contractAddress The address of the utility contract template.
    function deactivateContract(address _contractAddress) external;

    /// @notice Update status of registered utility contract to true (active).
    /// @param _contractAddress The address of the utility contract template.
    function activateContract(address _contractAddress) external;

    /// @notice Returns information about the registered utility contract.
    /// @param _address The address of the utility contract.
    /// @return ContractInfo Struct containing fee, isActive status and registration timestamp.
    function getContractInfo(address _address) external view returns (ContractInfo memory);
}
