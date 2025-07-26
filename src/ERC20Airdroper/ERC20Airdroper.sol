//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Airdroper} from "./IERC20Airdroper.sol";

/// @title ERC20Airdroper - Utility contract for ERC20 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC20 tokens.
contract ERC20Airdroper is IERC20Airdroper, AbstractUtilityContract, Ownable {
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

    /// @inheritdoc IERC20Airdroper
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external override onlyOwner {
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

    /// @inheritdoc IERC20Airdroper
    function getInitData(
        address _deployManager,
        address _tokenAddress,
        uint256 _airdropAmount,
        address _treasury,
        address _owner
    ) external pure override returns (bytes memory) {
        return abi.encode(_deployManager, _tokenAddress, _airdropAmount, _treasury, _owner);
    }
}
