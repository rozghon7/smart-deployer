// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../UtilityContract/AbstractUtilityContract.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Airdroper} from "./IERC721Airdroper.sol";

/// @title ERC721Airdroper - Utility contract for ERC721 tokens distributions (airdrop).
/// @author rozghon7.
/// @notice This contract provides a distribution functionality for ERC721 tokens.
contract ERC721Airdroper is IERC721Airdroper, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() payable Ownable(msg.sender) {}

    /// @notice The ERC721 token contract from which tokens will be distributed.
    IERC721 public token;
    /// @notice Address which holding tokens for distribution.
    address public treasury;
    /// @notice Transfer limit of token transfers per airdrop call (7 is example).
    uint256 public constant MAX_AIRDROP_ITERATIONS = 7;

    /// @inheritdoc IERC721Airdroper
    function airdrop(address[] calldata receivers, uint256[] calldata tokenIds) external override onlyOwner {
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

    /// @inheritdoc IERC721Airdroper
    function getInitData(address _deployManager, address _token, address _treasury, address _owner)
        external
        pure
        override
        returns (bytes memory)
    {
        return abi.encode(_deployManager, _token, _treasury, _owner);
    }
}
