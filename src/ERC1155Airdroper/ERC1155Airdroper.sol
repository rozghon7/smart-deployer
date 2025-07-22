//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC1155Airdroper - Utility contract for ERC1155 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC1155 tokens.
contract ERC1155Airdroper is AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC1155 token contract from which tokens will be distributed.
    IERC1155 public token;
    /// @notice Address which holding tokens for distribution.
    address public treasury;
    /// @notice Transfer limit of token transfers per airdrop call (7 is example).
    uint256 public constant MAX_AIRDROP_ITERATIONS = 7;

    /// @dev Reverts if arrays length is different.
    error ArraysLengthMismatch();
    /// @dev Reverts if treasury doesn't approve tokens for ERC1155Airdropper.
    error NeedToApproveTokens();
    /// @dev Reverts if iterations quantity more than MAX_AIRDROP_ITTERATIONS.
    error IterationsQuantityMismatch();

    /// @notice Emitted when airdrop is sent.
    event AirdropSent(uint256 timestamp);

    /// @notice Distributes tokens to recipients from treasury address.
    /// @param receivers Users addresses to receive tokens.
    /// @param amounts Amount of tokens distribution for every receiver.
    /// @param tokenId The tokens IDs for distribution.
    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenId)
        external
        onlyOwner
    {
        require(tokenId.length <= MAX_AIRDROP_ITERATIONS, IterationsQuantityMismatch());
        require(receivers.length == tokenId.length, ArraysLengthMismatch());
        require(tokenId.length == amounts.length, ArraysLengthMismatch());
        require(token.isApprovedForAll(treasury, address(this)), NeedToApproveTokens());

        address treasuryAddress = treasury;

        for (uint256 i = 0; i < receivers.length;) {
            token.safeTransferFrom(treasuryAddress, receivers[i], tokenId[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }

        emit AirdropSent(block.timestamp);
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _tokenAddress, address _treasury, address _owner) =
            abi.decode(_initData, (address, address, address, address));

        setDeployManager(_deployManager);
        token = IERC1155(_tokenAddress);
        treasury = _treasury;
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @notice Helper to encode constructor-style init data.
    /// @param _deployManager Address of the DeployManager.
    /// @param _tokenAddress Address of ERC1155 token contract.
    /// @param _treasury Address holding the tokens.
    /// @param _owner New owner of the contract.
    /// @return Encoded initialization bytes.
    function getInitData(address _deployManager, address _tokenAddress, address _treasury, address _owner)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _tokenAddress, _treasury, _owner);
    }

}
