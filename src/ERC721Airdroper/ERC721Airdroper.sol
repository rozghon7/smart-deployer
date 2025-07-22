// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC721Airdroper - Utility contract for ERC721 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC721 tokens.
contract ERC721Airdroper is AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC721 token contract from which tokens will be distributed.
    IERC721 public token;
    /// @notice Address which holding tokens for distribution.
    address public treasury;
    /// @notice Transfer limit of token transfers per airdrop call (7 is example).
    uint256 public constant MAX_AIRDROP_ITERATIONS = 7;

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if treasury doesn't approve tokens for ERC721Airdropper.
    error NeedToApproveTokens();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param tokenIds The tokens IDs for distribution.
    function airdrop(address[] calldata receivers, uint256[] calldata tokenIds) external onlyOwner {
        require(MAX_AIRDROP_ITERATIONS >= tokenIds.length, IterationsQuantityMismatch());
        require(receivers.length == tokenIds.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < tokenIds.length;) {
            token.safeTransferFrom(treasuryAddress, receivers[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        emit AirdropSent(block.timestamp);
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _token, address _treasury, address _owner) =
            abi.decode(_initData, (address, address, address, address));

        setDeployManager(_deployManager);
        token = IERC721(_token);
        treasury = _treasury;

        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @notice Helper to encode constructor-style init data.
    /// @param _deployManager Address of the DeployManager.
    /// @param _token Address of ERC721 token contract.
    /// @param _treasury Address holding the tokens.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization bytes.
    function getInitData(address _deployManager, address _token, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _treasury, _owner);
    }
}
