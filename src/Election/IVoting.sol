//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/// @title IVoting - Interface for voting functionality.
/// @author rozghon7.
/// @notice This interface defines the structure and functions for managing an election.
interface IVoting {
    /// @notice Emitted when a user votes.
    event Voted(uint256 indexed index, address indexed voter);
    /// @notice Emitted when voting has started.
    event VotingStarted();

    /// @notice Parameters for the election.
    /// @param electors Array of electors' indices.
    /// @param votingMaxVotes Maximum number of votes allowed in the election.
    /// @param usersMaxVotes Maximum number of votes allowed per user.
    /// @param votingStartTime Timestamp when voting starts.
    /// @param votingEndTime Timestamp when voting ends.
    struct ElectionParameters {
        uint256[] electors;
        uint256 votingMaxVotes;
        uint256 usersMaxVotes;
        uint256 votingStartTime;
        uint256 votingEndTime;
    }

    /// @notice Reverts if the elector does not exist.
    /// @param _pickedElector The index of the elector that was picked.
    /// @param _totalElectors The total number of electors.
    error ElectorDoesNotExist(uint256 _pickedElector, uint256 _totalElectors);
    /// @notice Reverts if the owner tries to vote.
    error OwnerCanNotVote();
    /// @notice Reverts if the maximum number of votes has been reached.
    /// @param _totalReached The total number of votes that have been reached.
    error VotingMaxVotesReached(uint256 _totalReached);
    /// @notice Reverts if the user has reached their maximum number of votes.
    /// @param _totalUserVotes The total number of votes the user has cast.
    error UserMaxVotesReached(uint256 _totalUserVotes);
    /// @notice Reverts if the voting time is over.
    error VotingTimeIsOver();
    /// @notice Reverts if the voting has not started.
    error VotingDoesNotStarted();
    /// @notice Reverts if the voting start time is in the past.
    error VotingStartTimeShouldBeInFuture();
    /// @notice Reverts if the voting end time is before the start time.
    error VotingEndTimeShouldBeAfterStart();
    /// @notice Reverts if there are not enough electors.
    error NotEnoughtElectors();
    /// @notice Reverts if the voting has already started.
    error VotingAlreadyStarted();

    /// @notice Allows a user to vote for an elector.
    /// @param _number The index of the elector to vote for.
    function vote(uint256 _number) external;

    /// @notice Starts the voting process with the given parameters.
    /// @param _params The parameters for the election.
    function startVoting(ElectionParameters calldata _params) external;

    /// @notice Returns the index of the leading elector.
    /// @return The index of the leading elector.
    function getLeader() external view returns (uint256);

    /// @notice Returns the ABI-encoded initialization data for the contract.
    /// @param _deployManager The address of the deploy manager.
    /// @param _owner The address of the owner.
    /// @return The ABI-encoded initialization data.
    function getInitData(address _deployManager, address _owner) external pure returns (bytes memory);
}
