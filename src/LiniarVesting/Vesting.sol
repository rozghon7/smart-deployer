// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVesting} from "./IVesting.sol";
import {LibraryVesting} from "./LibraryVesting.sol";

/// @title Vesting Contract.
/// @author rozghon7.
/// @notice Manages token vesting schedules for beneficiaries.
contract Vesting is IVesting, AbstractUtilityContract, Ownable {
    using LibraryVesting for IVesting.VestingInfo;

    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC20 token that is being vested.
    IERC20 public token;
    /// @notice The total amount of tokens that have been allocated for vesting.
    uint256 public allocatedTokens;

    /// @notice A mapping of beneficiary addresses to their vesting information.
    mapping(address => IVesting.VestingInfo) public vestings;

    /// @inheritdoc IVesting
    function claim() public {
        VestingInfo storage vesting = vestings[msg.sender];

        if (!vesting.created) revert VestingNotFound();

        uint256 blocktimestamp = block.timestamp;

        if (blocktimestamp < vesting.startTime + vesting.cliff) {
            revert ClaimNotAvailable(blocktimestamp, vesting.startTime + vesting.cliff);
        }
        if (blocktimestamp < vesting.lastClaimTime + vesting.claimCooldown) {
            revert CooldownNotPassed(blocktimestamp, vesting.lastClaimTime);
        }

        uint256 claimable = claimableAmount(msg.sender);

        if (claimable == 0) revert NothingToClaim();
        if (claimable < vesting.minClaimAmount) revert BelowMinimalClaimAmount(claimable, vesting.minClaimAmount);

        unchecked {
            vesting.claimed = vesting.claimed + claimable;
            vesting.lastClaimTime = blocktimestamp;
            allocatedTokens = allocatedTokens - claimable;
        }

        require(token.transfer(msg.sender, claimable));

        emit Claim(msg.sender, claimable, blocktimestamp);
    }

    /// @inheritdoc IVesting
    function vestedAmount(address _claimer) public view returns (uint256) {
        return vestings[_claimer].vestedAmount();
    }

    /// @inheritdoc IVesting
    function claimableAmount(address _claimer) public view returns (uint256) {
        return vestings[_claimer].claimableAmount();
    }

    /// @inheritdoc IVesting
    function startVesting(IVesting.VestingParameters calldata parameters) external onlyOwner {
        if (parameters.beneficiary == address(0)) revert InvalidBeneficiary();
        if (parameters.duration == 0) revert DurationCantBeZero();
        if (parameters.totalAmount == 0) revert AmountCantBeZero();

        uint256 blocktimestamp = block.timestamp;

        if (parameters.startTime < blocktimestamp) revert StartTimeShouldBeFuture(parameters.startTime, blocktimestamp);
        if (parameters.claimCooldown > parameters.duration) {
            revert CooldownCantBeLongerThanDuration(parameters.claimCooldown, parameters.duration);
        }

        uint256 availableBalance = token.balanceOf(address(this)) - allocatedTokens;

        if (availableBalance < parameters.totalAmount) {
            revert InsufficientBalance(availableBalance, parameters.totalAmount);
        }

        VestingInfo storage vesting = vestings[parameters.beneficiary];

        if (vesting.created) {
            if (vesting.totalAmount != vesting.claimed) revert VestingAlreadyExists();
        }

        vesting.totalAmount = parameters.totalAmount;
        vesting.startTime = parameters.startTime;
        vesting.cliff = parameters.cliff;
        vesting.duration = parameters.duration;
        vesting.claimed = 0;
        vesting.lastClaimTime = 0;
        vesting.claimCooldown = parameters.claimCooldown;
        vesting.minClaimAmount = parameters.minClaimAmount;
        vesting.created = true;

        unchecked {
            allocatedTokens = allocatedTokens + parameters.totalAmount;
        }
        emit VestingCreated(parameters.beneficiary, parameters.totalAmount, blocktimestamp);
    }

    /// @inheritdoc IVesting
    function withdrawUnallocated(address _to) external onlyOwner {
        uint256 available = token.balanceOf(address(this)) - allocatedTokens;

        if (available == 0) revert NothingToWithdraw();

        require(token.transfer(_to, available));

        emit TokensWithdrawn(_to, available);
    }

    /// @inheritdoc AbstractUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _token, address _owner) = abi.decode(_initData, (address, address, address));

        setDeployManager(_deployManager);
        token = IERC20(_token);
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @inheritdoc IVesting
    function getInitData(address _deployManager, address _token, address _owner) external pure returns (bytes memory) {
        return abi.encode(_deployManager, _token, _owner);
    }
}
