// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "../UtilityContract/IUtilityContract.sol";
import {IDeployManager} from "./IDeployManager.sol";

/// @title DeployManager - Factory for utility contracts.
/// @author rozghon7.
/// @notice provides functionality to allow users deploy utility contracts by cloning registered templates.
contract DeployManager is IDeployManager, Ownable, ERC165 {
    /// @notice Initializes Ownable with deployer.
    constructor() payable Ownable(msg.sender) {}

    /// @dev Maps deployer address to array of deployed contracts addresses.
    mapping(address => address[]) public deployedContracts;
    /// @dev Maps information of registered contract address.
    mapping(address => ContractInfo) public contractsData;

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IDeployManager).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IDeployManager
    function deploy(address _utilityContract, bytes calldata _initData) external payable override returns (address) {
        ContractInfo memory info = contractsData[_utilityContract];

        require(info.registeredAt > 0, ContractDoesNotRegistered());
        require(info.isActive, ContractDoesNotActive());
        require(msg.value >= info.fee, NotEnoughFunds());

        address clone = Clones.clone(_utilityContract);

        require(IUtilityContract(clone).initialize(_initData), InitializationFailed());

        (bool success,) = payable(owner()).call{value: msg.value}("");
        if (!success) revert TransactionFailed();

        deployedContracts[msg.sender].push(clone);

        emit NewDeployment(msg.sender, clone, msg.value, block.timestamp);

        return clone;
    }

    /// @inheritdoc IDeployManager
    function addNewContract(address _contractAddress, uint256 _fee, bool _isActive) external override onlyOwner {
        require(
            IUtilityContract(_contractAddress).supportsInterface(type(IUtilityContract).interfaceId),
            ContractIsNotUtilityContract()
        );
        require(contractsData[_contractAddress].registeredAt == 0, ContractAlreadyRegistered());

        contractsData[_contractAddress] = ContractInfo({fee: _fee, isActive: _isActive, registeredAt: block.timestamp});

        emit NewContractAdded(_contractAddress, _fee, _isActive, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function updateFee(address _contractAddress, uint256 _newFee) external override onlyOwner {
        require(contractsData[_contractAddress].registeredAt > 0, ContractDoesNotRegistered());

        uint256 _oldFee = contractsData[_contractAddress].fee;
        contractsData[_contractAddress].fee = _newFee;

        emit ContractFeeUpdated(_contractAddress, _oldFee, _newFee, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function deactivateContract(address _address) external override onlyOwner {
        require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());

        contractsData[_address].isActive = false;

        emit ContractStatusUpdated(_address, false, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function activateContract(address _address) external override onlyOwner {
        require(contractsData[_address].registeredAt > 0, ContractDoesNotRegistered());

        contractsData[_address].isActive = true;

        emit ContractStatusUpdated(_address, true, block.timestamp);
    }

    /// @inheritdoc IDeployManager
    function getContractInfo(address _address) external view returns (ContractInfo memory) {
        return contractsData[_address];
    }
}
