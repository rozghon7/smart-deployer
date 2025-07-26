// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC20Claimer} from "./IERC20Claimer.sol";

/// @title ERC20Claimer Contract.
/// @author rozghon7.
/// @notice Manages the claiming of ERC20 tokens based on a Merkle proof.
contract ERC20Claimer is IERC20Claimer, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() Ownable(msg.sender) {}

    /// @notice The ERC20 token that is being claimed.
    IERC20 public token;
    /// @notice The Merkle root of the airdrop.
    bytes32 public merkleRoot;
    /// @notice The total amount of tokens claimed by users.
    uint256 public totalTokensClaimed;
    /// @notice The time until which claims are allowed.
    uint256 public timeForClaim;

    /// @notice A mapping to track if a user has already claimed their tokens.
    /// @dev This mapping is used to prevent double claims.
    mapping(address => bool) hasClaimed;

    /// @inheritdoc IERC20Claimer
    function claim(uint256 _amount, bytes32[] calldata proof) external override {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert NothingToClaim();

        require(token.balanceOf(address(this)) >= _amount, NotEnoughFundsInContract());

        hasClaimed[msg.sender] = true;
        totalTokensClaimed = totalTokensClaimed + _amount;

        bool succes = token.transfer(msg.sender, _amount);
        require(succes, TransactionFailed());

        emit TokensClaimed(msg.sender, _amount, block.timestamp);
    }

    /// @inheritdoc IERC20Claimer
    function airdropChecker(uint256 _amount, bytes32[] calldata proof) external view override returns (bool) {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        bool confirmed = MerkleProof.verify(proof, merkleRoot, leaf);
        if (confirmed) {
            return true;
        }

        return false;
    }

    /// @inheritdoc IERC20Claimer
    function recoverUnclaimed() public override onlyOwner {
        if (block.timestamp < timeForClaim) revert ClaimTimeDoesNotExpired();

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, NothingToWithdraw());

        bool succes = token.transfer(owner(), balance);
        require(succes, TransactionFailed());
    }

    /// @inheritdoc IERC20Claimer
    function deposit(uint256 _amount) external override onlyOwner {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, DepositFailed());

        emit DepositMade(msg.sender, _amount, address(token));
    }

    /// @inheritdoc AbstractUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _tokenAddress, bytes32 _merkleRoot, uint256 _timeForClaim, address _owner) =
            abi.decode(_initData, (address, address, bytes32, uint256, address));

        setDeployManager(_deployManager);
        token = IERC20(_tokenAddress);
        merkleRoot = _merkleRoot;
        timeForClaim = _timeForClaim + block.timestamp;
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @inheritdoc IERC20Claimer
    function getInitData(
        address _deployManager,
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _timeForClaim,
        address _owner
    ) external pure override returns (bytes memory) {
        return abi.encode(_deployManager, _tokenAddress, _merkleRoot, _timeForClaim, _owner);
    }
}
