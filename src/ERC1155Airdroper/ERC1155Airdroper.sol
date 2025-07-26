//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155Airdroper} from "./IERC1155Airdroper.sol";

/// @title ERC1155Airdroper - Utility contract for ERC1155 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC1155 tokens.
contract ERC1155Airdroper is IERC1155Airdroper, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC1155 token contract from which tokens will be distributed.
    IERC1155 public token;
    /// @notice Address which holding tokens for distribution.
    address public treasury;
    /// @notice Transfer limit of token transfers per airdrop call (7 is example).
    uint256 public constant MAX_AIRDROP_ITERATIONS = 7;

    /// @inheritdoc IERC1155Airdroper
    function airdrop(address[] calldata receivers, uint256[] calldata amounts, uint256[] calldata tokenId)
        external
        override
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

    /// @inheritdoc IERC1155Airdroper
    function getInitData(address _deployManager, address _tokenAddress, address _treasury, address _owner)
        external
        pure
        override
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _tokenAddress, _treasury, _owner);
    }
}
