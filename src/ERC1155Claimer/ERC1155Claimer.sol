// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC1155Claimer} from "./IERC1155Claimer.sol";

/// @title ERC1155Claimer Contract.
/// @author rozghon7.
/// @notice Manages the claiming of ERC1155 tokens based on a Merkle proof.
contract ERC1155Claimer is IERC1155Claimer, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() Ownable(msg.sender) {}

    /// @notice The ERC1155 token that is being claimed.
    IERC1155 public token;
    /// @notice The Merkle root of the airdrop.
    bytes32 public merkleRoot;
    /// @notice The total amount of tokens claimed by users.
    uint256 public totalTokensClaimed;
    /// @notice The time until which claims are allowed.
    uint256 public timeForClaim;

    /// @notice A mapping to track if a user has already claimed their tokens.
    /// @dev This mapping is used to prevent double claims.
    mapping(address => bool) hasClaimed;

    /// @inheritdoc IERC1155Claimer
    function claim(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes32[] calldata proof)
        external
        override
    {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (tokenIds.length == 0) revert IdLengthMustBeGreaterThanZero();
        if (tokenIds.length != amounts.length) revert LengthSizesMismatch();

        bytes32 leaf = keccak256(abi.encode(msg.sender, tokenIds, amounts));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert NothingToClaim();

        hasClaimed[msg.sender] = true;

        for (uint256 i = 0; i < tokenIds.length;) {
            if (tokenIds[i] == 0) revert TokenIdMustBeGreaterThanZero();
            if (amounts[i] == 0) revert AmountCanNotBeZero();
            require(token.balanceOf(address(this), tokenIds[i]) >= amounts[i], NotEnoughFundsInContract());
            token.safeTransferFrom(address(this), msg.sender, tokenIds[i], amounts[i], "");

            totalTokensClaimed += amounts[i];

            unchecked {
                ++i;
            }
        }

        emit TokensClaimed(msg.sender, tokenIds, amounts, block.timestamp);
    }

    /// @inheritdoc IERC1155Claimer
    function airdropChecker(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes32[] calldata proof)
        external
        view
        override
        returns (bool)
    {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();

        bytes32 leaf = keccak256(abi.encode(msg.sender, tokenIds, amounts));

        bool confirmed = MerkleProof.verify(proof, merkleRoot, leaf);
        if (confirmed) {
            return true;
        }

        return false;
    }

    /// @inheritdoc IERC1155Claimer
    function recoverUnclaimed(uint256[] calldata _tokenIdsToRecover, uint256[] calldata _amountsToRecover)
        public
        override
        onlyOwner
    {
        if (block.timestamp < timeForClaim) revert ClaimTimeDoesNotExpired();
        if (_tokenIdsToRecover.length == 0) revert IdLengthMustBeGreaterThanZero();
        if (_tokenIdsToRecover.length != _amountsToRecover.length) revert LengthSizesMismatch();

        for (uint256 i = 0; i < _tokenIdsToRecover.length;) {
            uint256 tokenId = _tokenIdsToRecover[i];
            uint256 amount = _amountsToRecover[i];

            if (tokenId == 0) revert TokenIdMustBeGreaterThanZero();
            if (amount == 0) revert AmountCanNotBeZero();

            require(token.balanceOf(address(this), tokenId) >= amount, NotEnoughFundsInContract());

            token.safeTransferFrom(address(this), owner(), tokenId, amount, "");

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IERC1155Claimer
    function deposit(uint256[] calldata _tokenIds, uint256[] calldata _amounts) external override onlyOwner {
        if (_tokenIds.length == 0) revert IdLengthMustBeGreaterThanZero();
        if (!token.isApprovedForAll(msg.sender, address(this))) revert NotApprovedForAll();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 _amount = _amounts[i];

            if (_amount == 0) revert AmountCanNotBeZero();
            if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();

            require(token.balanceOf(msg.sender, _tokenId) >= _amount, NotEnoughFunds());

            token.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }

        emit DepositMade(msg.sender, _tokenIds, _amounts, address(token));
    }

    /// @inheritdoc AbstractUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _tokenAddress, bytes32 _merkleRoot, uint256 _timeForClaim, address _owner) =
            abi.decode(_initData, (address, address, bytes32, uint256, address));

        setDeployManager(_deployManager);
        token = IERC1155(_tokenAddress);
        merkleRoot = _merkleRoot;
        timeForClaim = _timeForClaim + block.timestamp;
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @inheritdoc IERC1155Claimer
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
