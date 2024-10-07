// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibRewards} from "../libraries/LibRewards.sol";
import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

/// @title RewardsFacet
/// @author Shiva Shanmuganathan
/// @dev Facet contract for managing rewards and queue-related functionalities.
contract RewardsFacet {
    /// @dev Initializes the global queue. Only the contract owner can call this function.
    function initializeGlobalQueue() external {
        LibContractOwner.enforceIsContractOwner();
        LibRewards.initializeGlobalQueue();
    }

    /// @dev Claim the rewards for the caller.
    /// @return rewardUNIM The total amount of UNIM tokens that were claimed.
    /// @return rewardDarkMarks The total amount of DarkMarks tokens that were claimed.
    function claimRewards()
        external
        returns (uint256 rewardUNIM, uint256 rewardDarkMarks)
    {
        uint256 availableGas = gasleft();
        (rewardUNIM, rewardDarkMarks) = LibRewards.claimRewards();
        LibGasReturner.returnGasToUser(
            "claimRewards",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }

    /// @dev Returns the owed UNIM and Dark Marks rewards for the specified user.
    /// @param user The address of the user to get the rewards for.
    /// @return rewardUNIM The owed UNIM rewards for the user.
    /// @return rewardDarkMarks The owed Dark Marks rewards for the user.
    function getPlayerRewards(
        address user
    ) external view returns (uint256 rewardUNIM, uint256 rewardDarkMarks) {
        return LibRewards.getPlayerRewards(user);
    }

    /// @dev Returns the total claimable UNIM rewards.
    /// @return claimableUNIM The total claimable UNIM rewards.
    function getClaimableUNIM(
        uint256 waveId
    ) external view returns (uint256 claimableUNIM) {
        claimableUNIM = LibRewards.getClaimableUNIM(waveId);
    }

    /// @dev Returns the total claimable Dark Marks rewards.
    /// @return claimableDarkMarks The total claimable Dark Marks rewards.
    function getClaimableDarkMarks(
        uint256 waveId
    ) external view returns (uint256 claimableDarkMarks) {
        claimableDarkMarks = LibRewards.getClaimableDarkMarks(waveId);
    }

    /// @dev Sets the wave UNIM rewards amount. Only the contract owner can call this function.
    /// @param _waveUNIM The new wave UNIM rewards amount to set.
    function setWaveUNIM(uint256 _waveUNIM) external {
        LibContractOwner.enforceIsContractOwner();
        LibRewards.setWaveUNIM(_waveUNIM);
    }

    /// @dev Returns the current wave UNIM rewards amount.
    /// @return waveUNIM The current wave UNIM rewards amount.
    function getWaveUNIM() external view returns (uint256 waveUNIM) {
        return LibRewards.getWaveUNIM();
    }

    /// @dev Sets the wave Dark Marks rewards amount. Only the contract owner can call this function.
    /// @param _waveDarkMarks The new wave Dark Marks rewards amount to set.
    function setWaveDarkMarks(uint256 _waveDarkMarks) external {
        LibContractOwner.enforceIsContractOwner();
        LibRewards.setWaveDarkMarks(_waveDarkMarks);
    }

    /// @dev Returns the current wave Dark Marks rewards amount.
    /// @return waveDarkMarks The current wave Dark Marks rewards amount.
    function getWaveDarkMarks() external view returns (uint256 waveDarkMarks) {
        return LibRewards.getWaveDarkMarks();
    }

    /// @dev Checks if the queue for the specified user has been initialized.
    /// @param user The address of the user to check the queue for.
    /// @return isInitialized True if the queue for the specified user has been initialized, false otherwise.
    function isPlayerQueueInitialized(
        address user
    ) external view returns (bool isInitialized) {
        return LibRewards.isPlayerQueueInitialized(user);
    }

    /// @dev Checks if the global queue has been initialized.
    /// @return isInitialized True if the global queue has been initialized, false otherwise.
    function isGlobalQueueInitialized()
        external
        view
        returns (bool isInitialized)
    {
        return LibRewards.isGlobalQueueInitialized();
    }

    /// @dev Returns the length of the queue for the specified user.
    /// @param user The address of the user to get the queue length for.
    /// @return length The length of the queue for the specified user.
    function getPlayerQueueLength(
        address user
    ) external view returns (uint256 length) {
        return LibRewards.getPlayerQueueLength(user);
    }

    /// @dev Returns the length of the global queue.
    /// @return length The length of the global queue.
    function getGlobalQueueLength() external view returns (uint256 length) {
        return LibRewards.getGlobalQueueLength();
    }

    /// @dev Returns the front item in the queue for the specified user.
    /// @param user The address of the user to get the front item for.
    /// @return timestamp The timestamp of the front item in the queue for the specified user.
    /// @return quantity The quantity associated with the front item in the queue for the specified user.
    function getPlayerQueueFront(
        address user
    ) external view returns (uint256 timestamp, uint256 quantity) {
        return LibRewards.getPlayerQueueFront(user);
    }

    /// @dev Returns the front item in the global queue.
    /// @return waveId The waveId of the front item in the global queue.
    /// @return quantity The quantity associated with the front item in the global queue.
    function getGlobalQueueFront()
        external
        view
        returns (
            uint256 waveId,
            uint256 quantity,
            uint256 waveUNIM,
            uint256 waveDarkMarks,
            uint256 unclaimedUnim,
            uint256 unclaimedDarkmarks
        )
    {
        return LibRewards.getGlobalQueueFront();
    }

    /// @dev Returns the tail item in the queue for the specified user.
    /// @param user The address of the user to get the tail item for.
    /// @return waveId The waveId of the tail item in the queue for the specified user.
    /// @return quantity The quantity associated with the tail item in the queue for the specified user.
    function getPlayerQueueTail(
        address user
    ) external view returns (uint256 waveId, uint256 quantity) {
        return LibRewards.getPlayerQueueTail(user);
    }

    /// @dev Returns the tail item in the global queue.
    /// @return waveId The waveId of the tail item in the global queue.
    /// @return quantity The quantity associated with the tail item in the global queue.
    function getGlobalQueueTail()
        external
        view
        returns (
            uint256 waveId,
            uint256 quantity,
            uint256 waveUNIM,
            uint256 waveDarkMarks,
            uint256 unclaimedUnim,
            uint256 unclaimedDarkmarks
        )
    {
        return LibRewards.getGlobalQueueTail();
    }

    /// @dev Returns the item at the given index in the queue for the specified user.
    /// @param user The address of the user to get the item from the queue for.
    /// @param index The index of the item to retrieve.
    /// @return waveId The waveId of the item at the given index in the queue for the specified user.
    /// @return quantity The quantity associated with the item at the given index in the queue for the specified user.
    function getPlayerQueueAtIndex(
        address user,
        uint256 index
    ) external view returns (uint256 waveId, uint256 quantity) {
        return LibRewards.getPlayerQueueAtIndex(user, index);
    }

    /// @dev Returns the item at the given index in the global queue.
    /// @param index The index of the item to retrieve.
    /// @return waveId The waveId of the item at the given index in the global queue.
    /// @return quantity The quantity associated with the item at the given index in the global queue.
    function getGlobalQueueAtIndex(
        uint256 index
    )
        external
        view
        returns (
            uint256 waveId,
            uint256 quantity,
            uint256 waveUNIM,
            uint256 waveDarkMarks,
            uint256 unclaimedUnim,
            uint256 unclaimedDarkmarks
        )
    {
        return LibRewards.getGlobalQueueAtIndex(index);
    }

    /// @dev Returns the entire queue for the specified user.
    /// @param user The address of the user to get the queue for.
    /// @return waveIds The array of waveIds of items in the queue for the specified user.
    /// @return quantities The array of quantities associated with items in the queue for the specified user.
    function getPlayerQueue(
        address user
    )
        external
        view
        returns (uint256[] memory waveIds, uint256[] memory quantities)
    {
        return LibRewards.getPlayerQueue(user);
    }

    /// @dev Returns the entire global queue.
    /// @return waveIds The array of waveIds of items in the global queue.
    /// @return quantities The array of quantities associated with items in the global queue.
    function getGlobalQueue()
        external
        view
        returns (uint256[] memory waveIds, uint256[] memory quantities)
    {
        return LibRewards.getGlobalQueue();
    }

    /// @notice Retrieves the wave rewards (UNIM and Dark Marks) from the global queue.
    /// @return waveUNIM An array containing the UNIM rewards for each wave in the global queue.
    /// @return waveDarkMarks An array containing the Dark Marks rewards for each wave in the global queue.
    function getGlobalQueueWaveRewards()
        external
        view
        returns (uint256[] memory waveUNIM, uint256[] memory waveDarkMarks)
    {
        return LibRewards.getGlobalQueueWaveRewards();
    }

    /// @notice Retrieves the unclaimed rewards (Dark Marks and UNIM) from the global queue.
    /// @return unclaimedUnim An array containing the unclaimed UNIM for each wave in the global queue.
    /// @return unclaimedDarkmarks An array containing the unclaimed Dark Marks for each wave in the global queue.
    function getGlobalQueueUnclaimedRewards()
        external
        view
        returns (
            uint256[] memory unclaimedUnim,
            uint256[] memory unclaimedDarkmarks
        )
    {
        return LibRewards.getGlobalQueueUnclaimedRewards();
    }

    /// @notice Retrieves the current wave count from the rewards storage.
    /// @return waveCount The current wave count value.
    function getWaveCount() external view returns (uint256 waveCount) {
        return LibRewards.getWaveCount();
    }

    /// @notice Retrieves the current wave time from the rewards storage.
    /// @return waveTime The current wave time value.
    function getWaveTime() external view returns (uint256 waveTime) {
        return LibRewards.getWaveTime();
    }

    /// @notice Retrieves the UNIM tokens for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the UNIM tokens.
    /// @return waveUNIM The amount of UNIM tokens for the specified wave ID.
    function getWaveUNIMByWaveId(
        uint256 waveId
    ) external view returns (uint256 waveUNIM) {
        return LibRewards.getWaveUNIMByWaveId(waveId);
    }

    /// @notice Retrieves the Dark Marks for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the Dark Marks.
    /// @return waveDarkMarks The amount of Dark Marks for the specified wave ID.
    function getWaveDarkMarksByWaveId(
        uint256 waveId
    ) external view returns (uint256 waveDarkMarks) {
        return LibRewards.getWaveDarkMarksByWaveId(waveId);
    }

    /// @notice Calculates the current wave count
    /// @return waveCount The current wave count, derived from the system's reward logic.
    function calculateCurrentWaveCount()
        external
        view
        returns (uint256 waveCount)
    {
        (waveCount, ) = LibRewards.calculateCurrentWaveData();
    }

    /// @dev Retrieves the total unclaimed rewards in the global queue.
    /// Iterates through the queue, summing the unclaimed UNIM and Darkmarks rewards.
    /// @return unclaimedUnim The total amount of unclaimed UNIM tokens.
    /// @return unclaimedDarkmarks The total amount of unclaimed Darkmarks.
    function getUnclaimedRewards()
        external
        view
        returns (uint256 unclaimedUnim, uint256 unclaimedDarkmarks)
    {
        return LibRewards.getUnclaimedRewards();
    }

    /// @dev Retrieves the total distributed rewards.
    /// @return distributedUNIM The total amount of distributed UNIM tokens.
    /// @return distributedDarkMarks The total amount of distributed Darkmarks.
    function getDistributedRewards()
        external
        view
        returns (uint256 distributedUNIM, uint256 distributedDarkMarks)
    {
        return LibRewards.getDistributedRewards();
    }

    /// @notice Returns both the daily UNIM and DarkMarks rewards.
    /// @return dailyUNIM The quantity of UNIM allocated for the current wave.
    /// @return dailyDarkMarks The quantity of DarkMarks allocated for the current wave.
    function getDailyRewards()
        external
        view
        returns (uint256 dailyUNIM, uint256 dailyDarkMarks)
    {
        return LibRewards.getDailyRewards();
    }

    /// @dev Calculates the contribution percentage of a specific user in the last 7 days except the last 24 hours.
    /// It calculates the total contribution of a user in comparison to the global contributions.
    /// @param user The address of the user whose contribution percentage is being calculated.
    /// @return contributionPercentage The percentage of the user's contribution in the last 7 days except the last 24 hours.
    function getContributionPercentage(
        address user
    ) external view returns (uint256 contributionPercentage) {
        return LibRewards.getContributionPercentage(user);
    }
}
