//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICrowdFunding} from "./ICrowdFunding.sol";

/// @title Crowdfunding - Utility contract for raising funds with vesting-based fund release.
/// @author rozghon7.
/// @notice This contract allows users to contribute funds towards a fundraising goal, with vesting logic on success.
contract Crowdfunding is ICrowdFunding, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice VestingWallet instance for fundraiser.
    VestingWallet public vestingWallet;
    /// @notice Address of the fundraiser who will receive vested funds.
    address public fundraiser;
    /// @notice Duration of the vesting schedule in seconds.
    uint256 public vestingTime;
    /// @notice Target amount to reach for starting vesting.
    uint256 public goal;
    /// @notice Total current contributions in pool.
    uint256 public donationPool;
    /// @notice Timestamp when fundraising goal was reached.
    uint256 public startTimestamp;
    /// @notice Flag indicating if the goal has been reached.
    bool public poolReached;
    /// @notice Flag indicating if vesting has started.
    bool public vestingStarted;

    /// @notice Stores user contribution history.
    mapping(address => uint256) donationsHistory;

    /// @inheritdoc ICrowdFunding
    function contribute() public payable {
        if (poolReached) revert PoolHasReached();
        if (donationPool + msg.value > goal) revert InvalidValue();

        donationPool = donationPool + msg.value;
        donationsHistory[msg.sender] = donationsHistory[msg.sender] + msg.value;

        startVestingCheck();

        emit ContributionReceived(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Internal function that starts the vesting schedule if fundraising goal is reached.
    /// @dev Deploys VestingWallet and sends contract balance.
    /// @return Address of the deployed VestingWallet contract.
    function startVestingCheck() internal returns (address) {
        address _vestingContractAddress  = address(0);
        if (donationPool == goal) {
            startTimestamp = block.timestamp;
            poolReached = true;
            vestingStarted = true;

            vestingWallet = new VestingWallet(fundraiser, uint64(startTimestamp), uint64(vestingTime));
            _vestingContractAddress = address(vestingWallet);

            (bool success,) = address(vestingWallet).call{value: address(this).balance}("");
            require(success, TransactionFailed());
        }

        if (_vestingContractAddress != address(0)) emit VestingStarted(address(vestingWallet), block.timestamp);

        return address(vestingWallet);
    }

    /// @inheritdoc ICrowdFunding
    function refund(uint256 _value) external {
        if (poolReached) revert PoolHasReachedAndYouCantRefund();

        uint256 userFunds = donationsHistory[msg.sender];

        if (userFunds == 0) revert NothingToRefund();
        if (userFunds < _value) revert AmountTooHigh();

        (bool success, ) = payable(msg.sender).call{value : _value}("");
        if (!success) revert TransactionFailed();

        donationPool = donationPool - _value;
        donationsHistory[msg.sender] = userFunds - _value;

        emit RefundProcessed(msg.sender, _value, block.timestamp);
    }

    /// @inheritdoc ICrowdFunding
    function withdraw() external {
        if (msg.sender != fundraiser) revert OnlyFundraiserAllowed();
        if (address(vestingWallet) == address(0)) revert VestingNotStarted();

        vestingWallet.release();

        emit FundsWithdrawnFromVesting(fundraiser, block.timestamp);
    }

    /// @notice Handles plain ether transfers as a fallback contribution method.
    receive() external payable {
        if (poolReached) revert PoolHasReached();
        contribute();
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, uint256 _goal, address _fundraiser, uint256 _vestingTime, address _owner) =
            abi.decode(_initData, (address, uint256, address, uint256, address));

        goal = _goal;
        fundraiser = _fundraiser;
        vestingTime = _vestingTime;

        _transferOwnership(_owner);

        setDeployManager(_deployManager);
        initialized = true;
        return true;
    }

    /// @inheritdoc ICrowdFunding
    function getInitData(
        address _deployManager,
        uint256 _goal,
        address _fundraiser,
        uint64 _vestingTime,
        address _owner
    ) external pure returns (bytes memory) {
        return abi.encode(_deployManager, _goal, _fundraiser, _vestingTime, _owner);
    }
}
