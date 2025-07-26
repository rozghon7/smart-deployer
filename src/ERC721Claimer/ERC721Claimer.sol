// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC721Claimer} from "./IERC721Claimer.sol";

/// @title ERC721Claimer Contract.
/// @author rozghon7.
/// @notice Manages the claiming of ERC721 tokens based on a Merkle proof.
contract ERC721Claimer is IERC721Claimer, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() Ownable(msg.sender) {}

    /// @notice The ERC721 token that is being claimed.
    IERC721 public token;
    /// @notice The Merkle root of the airdrop.
    bytes32 public merkleRoot;
    /// @notice The total amount of NFT's claimed by users.
    uint256 public totalNFTsClaimed;
    /// @notice The time until which claims are allowed.
    uint256 public timeForClaim;

    /// @notice A mapping to track if a user has already claimed their NFT's.
    /// @dev This mapping is used to prevent double claims.
    mapping(address => bool) hasClaimed;

    /// @inheritdoc IERC721Claimer
    function claim(uint256 _tokenId, bytes32[] calldata proof) external override {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (_tokenId == 0) revert TokenIdMustBeGreaterThanZero();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert NothingToClaim();

        require(token.ownerOf(_tokenId) == address(this), NFTNotOwnedByContract());

        hasClaimed[msg.sender] = true;
        totalNFTsClaimed += 1;

        token.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit NFTClaimed(msg.sender, _tokenId, block.timestamp);
    }

    /// @inheritdoc IERC721Claimer
    function airdropChecker(uint256 _tokenId, bytes32[] calldata proof) external view override returns (bool) {
        if (block.timestamp > timeForClaim) revert TooLateForClaim();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokenId));

        bool confirmed = MerkleProof.verify(proof, merkleRoot, leaf);
        if (confirmed) {
            return true;
        }

        return false;
    }

    /// @inheritdoc IERC721Claimer
    function recoverUnclaimed(uint256[] calldata _tokenIdsToRecover) public override onlyOwner {
        if (block.timestamp < timeForClaim) revert ClaimTimeDoesNotExpired();
        if (_tokenIdsToRecover.length == 0) revert IdLengthMustBeGreaterThanZero();

        for (uint256 i = 0; i < _tokenIdsToRecover.length;) {
            uint256 tokenId = _tokenIdsToRecover[i];
            if (tokenId == 0) revert TokenIdMustBeGreaterThanZero();
            if (token.ownerOf(tokenId) != address(this)) revert NFTNotOwnedByContract();

            token.safeTransferFrom(address(this), owner(), tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IERC721Claimer
    function deposit(uint256[] calldata _tokenIds) external override onlyOwner {
        if (_tokenIds.length == 0) revert IdLengthMustBeGreaterThanZero();
        if (!token.isApprovedForAll(msg.sender, address(this))) revert NFTsNotApprovedForAll();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (_tokenIds[i] == 0) revert TokenIdMustBeGreaterThanZero();

            token.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        emit DepositMade(msg.sender, _tokenIds, address(token));
    }

    /// @inheritdoc AbstractUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _tokenAddress, bytes32 _merkleRoot, uint256 _timeForClaim, address _owner) =
            abi.decode(_initData, (address, address, bytes32, uint256, address));

        setDeployManager(_deployManager);
        token = IERC721(_tokenAddress);
        merkleRoot = _merkleRoot;
        timeForClaim = _timeForClaim + block.timestamp;
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @inheritdoc IERC721Claimer
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
