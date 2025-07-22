//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20Airdroper - Utility contract for ERC20 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC20 tokens.
contract ERC20Airdroper is AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC20 token contract from which tokens will be distributed.
    IERC20 public token;
    /// @notice Amount of tokens for allowance check.
    uint256 public amount;
    /// @notice Address which holding tokens for distribution.
    address public treasury;
    /// @notice Transfer limit of token transfers per airdrop call (7 is example).
    uint256 public constant MAX_AIRDROP_ITERATIONS = 7;

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if tresuary doesn't approve enough tokens for ERC721Airdropper.
    error NotEnoughApprovedTokens();
    /// @dev Reverts if ERC20 transfer fails.
    error TransferToAddressFailed();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param amounts Amount of tokens distribution for every receiver.
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner {
        require(MAX_AIRDROP_ITERATIONS >= receivers.length, IterationsQuantityMismatch());
        require(receivers.length == amounts.length, ArraysLengthMismatch());
        require(token.allowance(treasury, address(this)) >= amount, NotEnoughApprovedTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < receivers.length;) {
            require(token.transferFrom(treasuryAddress, receivers[i], amounts[i]), TransferToAddressFailed());
            unchecked {
                ++i;
            }
        }

        emit AirdropSent(block.timestamp);
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _tokenAddress, uint256 _airdropAmount, address _treasury, address _owner) =
            abi.decode(_initData, (address, address, uint256, address, address));

        setDeployManager(_deployManager);
        token = IERC20(_tokenAddress);
        amount = _airdropAmount;
        treasury = _treasury;
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

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
    ) external pure returns (bytes memory) {
        return abi.encode(_deployManager, _tokenAddress, _airdropAmount, _treasury, _owner);
    }
}
