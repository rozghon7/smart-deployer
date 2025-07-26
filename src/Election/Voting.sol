//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../UtilityContract/AbstractUtilityContract.sol";
import {IVoting} from "./IVoting.sol";

/// @title Voting Contract.
/// @author rozghon7.
/// @notice Manages the voting process for electors in an election.
contract Voting is IVoting, AbstractUtilityContract, Ownable {
    /// @notice Initializes Ownable with the deployer (which will be superseded by _owner during initialization).
    constructor() Ownable(msg.sender) {}

    /// @notice The parameters for the election.
    /// @dev This struct contains the electors, maximum votes, and voting times.
    ElectionParameters public electionParams;

    /// @notice The total number of votes cast in the election.
    uint256 public totalVotes;
    /// @notice Indicates whether the voting has started.
    bool public votingStarted;

    /// @dev Modifier to check if the voting has started.
    modifier VotingExists() {
        if (!votingStarted) revert VotingDoesNotStarted();
        _;
    }

    /// @notice A mapping of user addresses to the number of votes they have cast.
    mapping(address => uint256) public userVotes;
    /// @notice A mapping of elector indices to their scores.
    mapping(uint256 => uint256) public electorsScores;

    /// @inheritdoc IVoting
    function vote(uint256 _number) external override VotingExists {
        ElectionParameters memory _params = electionParams;

        if (msg.sender == owner()) revert OwnerCanNotVote();
        if (block.timestamp < _params.votingStartTime) revert VotingDoesNotStarted();
        if (block.timestamp > _params.votingEndTime) revert VotingTimeIsOver();
        if (_params.votingMaxVotes > 0 && totalVotes == _params.votingMaxVotes) {
            revert VotingMaxVotesReached(totalVotes);
        }
        if (_number >= _params.electors.length) revert ElectorDoesNotExist(_number, _params.electors.length);
        if (_params.usersMaxVotes > 0 && userVotes[msg.sender] == _params.usersMaxVotes) {
            revert UserMaxVotesReached(userVotes[msg.sender]);
        }

        totalVotes = totalVotes + 1;
        userVotes[msg.sender] = userVotes[msg.sender] + 1;
        electorsScores[_number] = electorsScores[_number] + 1;

        emit Voted(_number, msg.sender);
    }

    /// @inheritdoc IVoting
    function getLeader() external view override VotingExists returns (uint256) {
        uint256 leader;

        for (uint256 i = 0; i < electionParams.electors.length;) {
            if (electorsScores[i] > electorsScores[leader]) {
                leader = i;
            }
            unchecked {
                ++i;
            }
        }

        return leader;
    }

    /// @inheritdoc IVoting
    function startVoting(ElectionParameters calldata _params) external override onlyOwner {
        if (votingStarted) revert VotingAlreadyStarted();
        if (_params.votingStartTime <= block.timestamp) revert VotingStartTimeShouldBeInFuture();
        if (_params.votingEndTime <= _params.votingStartTime) revert VotingEndTimeShouldBeAfterStart();
        if (_params.electors.length < 2) revert NotEnoughtElectors();

        electionParams = _params;

        votingStarted = true;
        totalVotes = 0;

        emit VotingStarted();
    }

    /// @inheritdoc IUtilityContract
    function initialize(bytes memory _initData) external override notInitialized returns (bool) {
        (address _deployManager, address _owner) = abi.decode(_initData, (address, address));

        setDeployManager(_deployManager);
        _transferOwnership(_owner);

        initialized = true;
        return true;
    }

    /// @inheritdoc IVoting
    function getInitData(address _deployManager, address _owner) external pure override returns (bytes memory) {
        return abi.encode(_deployManager, _owner);
    }
}
