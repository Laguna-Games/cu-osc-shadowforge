// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {LibPlayerQueue} from "./LibPlayerQueue.sol";
import {LibGlobalQueue} from "./LibGlobalQueue.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibTime} from "./LibTime.sol";
import {IUNIMControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IUNIMControllerFacet.sol";
import {IDarkMarksControllerFacet} from "../../lib/cu-osc-common/src/interfaces/IDarkMarksControllerFacet.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

/// @title LibRewards
/// @author Shiva Shanmuganathan
/// @dev Implementation of the daily rewards in minion hatchery
library LibRewards {
    event ClaimedRewards(
        address indexed player,
        uint256 rewardUNIM,
        uint256 rewardDarkMarks
    );
    event AddedToQueue(
        address indexed player,
        uint256 waveId,
        uint256 quantity
    );
    event BegunNewWave(
        uint256 newWaveId,
        uint256 prevWaveTime,
        uint256 newWaveTime
    );

    // Position to store the rewards storage
    bytes32 private constant REWARD_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Rewards.Storage");

    using LibPlayerQueue for LibPlayerQueue.QueueStorage;
    using LibGlobalQueue for LibGlobalQueue.QueueStorage;

    // Reward storage struct that holds all relevant reward data
    struct LibRewardsStorage {
        mapping(address => LibPlayerQueue.QueueStorage) playerQueue; // Player-specific reward queue
        LibGlobalQueue.QueueStorage globalQueue; // Global reward queue
        uint256 waveUNIM; // Amount of UNIM tokens to be released per wave
        uint256 waveDarkMarks; // Amount of DarkMarks tokens to be released per wave
        uint256 waveTime; // Timestamp of the current reward wave
        uint256 waveCount; // Number of reward waves
        bool initialized; // Whether the reward system has been initialized
        uint256 distributedUNIM; // Amount of UNIM tokens distributed
        uint256 distributedDarkMarks; // Amount of DarkMarks tokens distributed
    }

    /// @notice Initializes the global reward queue.
    /// @dev Must be called once before using the reward system. This function sets the reward wave.
    function initializeGlobalQueue() internal {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        // initialize
        require(
            globalQueue.isInitialized() == false,
            "Global Queue already initialised"
        );
        globalQueue.initialize();
        beginNewWave();
        lrs.initialized = true;
    }

    /// @notice Begins the current reward wave
    /// @dev Should be called whenever a new reward wave starts.
    /// @dev This should happen approximately every 24 hours depending on user minion creation.
    /// @dev Updates unclaimed reward quantities.
    /// @custom:emits BegunNewWave
    function beginNewWave() internal {
        LibRewardsStorage storage lrs = rewardStorage();
        uint256 lastWaveTime = lrs.waveTime;
        if (lrs.initialized) {
            (lrs.waveCount, lrs.waveTime) = calculateCurrentWaveData();
        } else {
            lrs.waveCount = lrs.waveCount + 1;
            lrs.waveTime = calculateMidnightUTCTime();
        }

        emit BegunNewWave(lrs.waveCount, lastWaveTime, lrs.waveTime);
    }

    /// @notice Calculate Current Wave Data
    /// @dev Calculates the current wave count and the corresponding wave time in UTC, considering midnight as the beginning of a new wave.
    /// @return currentWaveCount The current wave count, including any new waves since the last recorded wave time.
    /// @return currentWaveTime The timestamp of the beginning of the current wave, corresponding to midnight UTC on the current day.
    function calculateCurrentWaveData()
        internal
        view
        returns (uint256 currentWaveCount, uint256 currentWaveTime)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        uint256 lastWaveTime = lrs.waveTime;
        currentWaveTime = calculateMidnightUTCTime();
        uint256 waveCountToAdd = (currentWaveTime - lastWaveTime) /
            LibTime.SECONDS_PER_DAY;
        currentWaveCount = lrs.waveCount + waveCountToAdd;
    }

    /// @notice Calculate Midnight UTC Time
    /// @dev Calculates the timestamp corresponding to midnight UTC of the current day. This is used to identify the beginning of a new wave.
    /// @return newWaveTime The timestamp representing midnight UTC on the current day.
    function calculateMidnightUTCTime()
        internal
        view
        returns (uint256 newWaveTime)
    {
        (uint year, uint month, uint day) = LibTime._daysToDate(
            block.timestamp / LibTime.SECONDS_PER_DAY
        );
        newWaveTime = LibTime.timestampFromDate(year, month, day);
    }

    /// @notice Adds player's contribution to player and global queue
    /// @dev This function should be triggered by a function in the facet layer when minions are created using recipes, passing the number of minions and the user creating them.
    /// @dev Adds a player to the reward queue for a given quantity of tokens.
    /// @param quantity The quantity of tokens to add to the player's reward queue.
    /// @param user The address of the player to add to the queue.
    function addToQueue(uint256 quantity, address user) internal {
        checkAndInitializePlayerQueue(user);

        (
            uint256 waveUNIM,
            uint256 waveDarkMarks,
            bool globalQueueUpdated
        ) = handleExpiredWave(
                rewardStorage().waveUNIM,
                rewardStorage().waveDarkMarks,
                quantity
            );

        handleQueueUpdates(
            user,
            rewardStorage().waveCount,
            quantity,
            waveUNIM,
            waveDarkMarks,
            globalQueueUpdated
        );

        emit AddedToQueue(user, rewardStorage().waveCount, quantity);
    }

    /// @notice Get the wave IDs for the start and end of a specified range based on the current wave count.
    /// @dev If the current wave count is greater than 1, the startWaveId is set to currentWaveCount - 1.
    ///      If the current wave count is greater or equal to 7, the endWaveId is set to currentWaveCount - 7.
    ///      Otherwise, startWaveId and endWaveId are set to 0.
    /// @return startWaveId The starting wave ID of the range.
    /// @return endWaveId The ending wave ID of the range.
    /// @return currentWaveCount The current wave count at the time of calling this function.
    function getWaveIdRange()
        internal
        view
        returns (
            uint256 startWaveId,
            uint256 endWaveId,
            uint256 currentWaveCount
        )
    {
        (currentWaveCount, ) = calculateCurrentWaveData();

        if (currentWaveCount > 1) {
            startWaveId = currentWaveCount - 1;
        } else {
            startWaveId = 0;
        }

        if (currentWaveCount >= 7) {
            endWaveId = currentWaveCount - 7;
        } else {
            endWaveId = 0;
        }

        return (startWaveId, endWaveId, currentWaveCount);
    }

    /// @notice Calculates the rewards owed to a player for a specific wave ID.
    /// @param waveId The ID of the wave for which to calculate the rewards.
    /// @param player The address of the player for whom to calculate the rewards.
    /// @return owedUNIM The amount of UNIM tokens owed to the player for the given wave ID.
    /// @return owedDarkMarks The amount of DarkMarks tokens owed to the player for the given wave ID.
    function calculateRewardsByWaveId(
        uint256 waveId,
        address player
    ) internal view returns (uint256 owedUNIM, uint256 owedDarkMarks) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[
            player
        ];
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;

        uint256 playerMinionQty = playerQueue.getQtyByWaveId(waveId);
        uint256 globalMinionQty = globalQueue.getQtyByWaveId(waveId);

        uint256 totalUNIM = globalQueue.getWaveUNIMByWaveId(waveId);
        uint256 totalDarkMarks = globalQueue.getWaveDarkMarksByWaveId(waveId);

        owedUNIM = (totalUNIM * playerMinionQty) / globalMinionQty;
        owedDarkMarks = (totalDarkMarks * playerMinionQty) / globalMinionQty;

        return (owedUNIM, owedDarkMarks);
    }

    /// @notice Handles the updates to both the player queue and global queue, enqueuing or updating the quantity as required.
    /// @param user The address of the user whose queue is to be updated.
    /// @param waveCount The current wave count at the time of the update.
    /// @param quantity The quantity to be added or updated in the queues.
    /// @param waveUNIM The amount of UNIM tokens associated with the wave.
    /// @param waveDarkMarks The amount of DarkMarks tokens associated with the wave.
    /// @param globalQueueUpdated A boolean flag indicating whether the global queue has already been updated for the wave.
    function handleQueueUpdates(
        address user,
        uint256 waveCount,
        uint256 quantity,
        uint256 waveUNIM,
        uint256 waveDarkMarks,
        bool globalQueueUpdated
    ) internal {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;

        if (!playerQueue.waveIdExistsInQueue(waveCount)) {
            // add to playerQueue
            playerQueue.enqueue(waveCount, quantity);
        } else {
            // update playerQueue
            playerQueue.updateQty(waveCount, quantity);
        }

        if (!globalQueue.waveIdExistsInQueue(waveCount)) {
            // add to globalQueue
            globalQueue.enqueue(
                waveCount,
                quantity,
                waveUNIM,
                waveDarkMarks,
                waveUNIM,
                waveDarkMarks
            );
        } else {
            if (!globalQueueUpdated) {
                // update globalQueue
                globalQueue.updateQty(waveCount, quantity);
            }
        }
    }

    /// @notice Ensures the player queue for a specific user is initialized, calling the initialize function if it has not been done yet.
    /// @param user The address of the user whose queue needs to be initialized if not already done.
    function checkAndInitializePlayerQueue(address user) internal {
        LibPlayerQueue.QueueStorage storage playerQueue = rewardStorage()
            .playerQueue[user];
        if (playerQueue.isInitialized() == false) {
            playerQueue.initialize();
        }
    }

    /// @notice Handle processing of an expired wave.
    /// @param waveUNIM The initial amount of UNIM for the wave.
    /// @param waveDarkMarks The initial amount of DarkMarks for the wave.
    /// @param quantity The quantity to be processed.
    /// @return _waveUNIM The updated amount of UNIM after handling the expired wave.
    /// @return _waveDarkMarks The updated amount of DarkMarks after handling the expired wave.
    /// @return _globalQueueUpdated A boolean flag indicating if the global queue was updated.
    ///
    /// This function checks if the current wave is expired and performs necessary operations
    /// such as dequeuing outdated waves, updating wave rewards, and adding new entries to the
    /// global queue. If the wave is not expired, the original parameters are returned unchanged.
    function handleExpiredWave(
        uint256 waveUNIM,
        uint256 waveDarkMarks,
        uint256 quantity
    )
        internal
        returns (
            uint256 _waveUNIM,
            uint256 _waveDarkMarks,
            bool _globalQueueUpdated
        )
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        if (isWaveExpired()) {
            (uint256 currentWaveCount, ) = calculateCurrentWaveData();
            // check if global queue has more than 7 days of txs
            if (globalQueue.hasOutdatedWaves(currentWaveCount)) {
                // getDequeueCount
                uint256 dequeueCount = globalQueue.getDequeueCount(
                    currentWaveCount
                );

                // get total unclaimed rewards in dequeued txs
                (
                    uint256 totalUnclaimedUNIM,
                    uint256 totalUnclaimedDarkMarks
                ) = globalQueue.getUnclaimedRewardsInQueue(currentWaveCount);

                for (uint256 i = 0; i < dequeueCount; i++) {
                    // dequeue
                    globalQueue.dequeue();
                }

                // update wave rewards
                waveUNIM = waveUNIM + totalUnclaimedUNIM;
                waveDarkMarks = waveDarkMarks + totalUnclaimedDarkMarks;
            }

            beginNewWave();

            // add to globalQueue
            globalQueue.enqueue(
                lrs.waveCount,
                quantity,
                waveUNIM,
                waveDarkMarks,
                waveUNIM,
                waveDarkMarks
            );
            return (waveUNIM, waveDarkMarks, true);
        }
        return (waveUNIM, waveDarkMarks, false);
    }

    /// @notice Claims the rewards for the calling user and transfers the corresponding tokens.
    /// @dev Dequeues contributions older than a day in player queue
    /// @dev Calculate rewards with the playerMinionsQty and globalMinionsQty in the last 7 days except the last 24 hours
    /// @return rewardUNIM The total amount of UNIM tokens that were claimed.
    /// @return rewardDarkMarks The total amount of DarkMarks tokens that were claimed.
    function claimRewards()
        internal
        returns (uint256 rewardUNIM, uint256 rewardDarkMarks)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[
            msg.sender
        ];
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;

        (
            uint256 startWaveId,
            uint256 endWaveId,
            uint256 currentWaveCount
        ) = getWaveIdRange();

        // loop from today's wave id back to the 6 waves before
        for (uint256 waveId = startWaveId; waveId > endWaveId; waveId--) {
            // check if wave id exists in both queues
            if (
                playerQueue.waveIdExistsInQueue(waveId) &&
                globalQueue.waveIdExistsInQueue(waveId)
            ) {
                // calculate rewards by wave id
                (
                    uint256 owedUNIM,
                    uint256 owedDarkMarks
                ) = calculateRewardsByWaveId(waveId, msg.sender);

                globalQueue.deductClaimedRewards(
                    waveId,
                    owedUNIM,
                    owedDarkMarks
                );

                rewardUNIM += owedUNIM;
                rewardDarkMarks += owedDarkMarks;
            }
        }

        uint256 playerDequeueCount = playerQueue.getDequeueCount(
            currentWaveCount
        );
        // dequeue txs older than 1 day in player queue
        for (uint256 i = 0; i < playerDequeueCount; i++) {
            playerQueue.dequeue();
        }

        // add distributed rewards
        lrs.distributedUNIM += rewardUNIM;
        lrs.distributedDarkMarks += rewardDarkMarks;

        // check if player has any rewards to redeem
        if (rewardUNIM > 0) {
            IUNIMControllerFacet(LibResourceLocator.gameBank()).mintUNIM(
                msg.sender,
                rewardUNIM
            );
        }
        if (rewardDarkMarks > 0) {
            IDarkMarksControllerFacet(LibResourceLocator.gameBank())
                .mintDarkMarks(msg.sender, rewardDarkMarks);
        }

        emit ClaimedRewards(msg.sender, rewardUNIM, rewardDarkMarks);
    }

    /// @notice Retrieves the current wave count from the rewards storage.
    /// @return waveCount The current wave count value.
    function getWaveCount() internal view returns (uint256 waveCount) {
        return rewardStorage().waveCount;
    }

    /// @notice Retrieves the current wave time from the rewards storage.
    /// @return waveTime The current wave time value.
    function getWaveTime() internal view returns (uint256 waveTime) {
        return rewardStorage().waveTime;
    }

    /// @notice Calculates the total rewards (UNIM and Dark Marks) for a specific user based on wave IDs.
    /// @param user The address of the user whose rewards are to be calculated.
    /// @return rewardUNIM The total UNIM rewards owed to the user.
    /// @return rewardDarkMarks The total Dark Marks rewards owed to the user.
    function getPlayerRewards(
        address user
    ) internal view returns (uint256 rewardUNIM, uint256 rewardDarkMarks) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;

        (
            uint256 startWaveId,
            uint256 endWaveId,
            uint256 currentWaveCount
        ) = getWaveIdRange();

        // loop from today's wave id back to the 6 waves before
        for (uint256 waveId = startWaveId; waveId > endWaveId; waveId--) {
            // check if wave id exists in both queues
            if (
                playerQueue.waveIdExistsInQueue(waveId) &&
                globalQueue.waveIdExistsInQueue(waveId)
            ) {
                // calculate rewards by wave id
                (
                    uint256 owedUNIM,
                    uint256 owedDarkMarks
                ) = calculateRewardsByWaveId(waveId, user);

                rewardUNIM += owedUNIM;
                rewardDarkMarks += owedDarkMarks;
            }
        }
        return (rewardUNIM, rewardDarkMarks);
    }

    /// @dev Internal function to get the length of the player-specific queue.
    /// @param user The address of the player whose queue length is to be retrieved.
    /// @return length The number of items in the player's queue.
    function getPlayerQueueLength(
        address user
    ) internal view returns (uint256 length) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        return playerQueue.length();
    }

    /// @dev Internal function to get the length of the global queue.
    /// @return length The number of items in the global queue.
    function getGlobalQueueLength() internal view returns (uint256 length) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        return globalQueue.length();
    }

    /// @dev Internal function to get the front (oldest) item of the player's queue.
    /// @param user The address of the player whose queue is being accessed.
    /// @return waveId The waveId of the front item in the player's queue.
    /// @return quantity The quantity associated with the front item in the player's queue.
    function getPlayerQueueFront(
        address user
    ) internal view returns (uint256 waveId, uint256 quantity) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        return playerQueue.peek();
    }

    /// @dev Internal function to get the front (oldest) item of the global queue.
    /// @return waveId The waveId of the front item in the global queue.
    /// @return quantity The quantity associated with the front item in the global queue.
    function getGlobalQueueFront()
        internal
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
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        return globalQueue.peek();
    }

    /// @dev Internal function to get the tail (newest) item of the player-specific queue.
    /// @param user The address of the player whose queue is being accessed.
    /// @return waveId The waveId of the tail item in the player-specific queue.
    /// @return quantity The quantity associated with the tail item in the player-specific queue.
    function getPlayerQueueTail(
        address user
    ) internal view returns (uint256 waveId, uint256 quantity) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        return playerQueue.peekLast();
    }

    /// @dev Internal function to get the tail (newest) item of the global queue.
    /// @return waveId The waveId of the tail item in the global queue.
    /// @return quantity The quantity associated with the tail item in the global queue.
    function getGlobalQueueTail()
        internal
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
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        return globalQueue.peekLast();
    }

    /// @dev Internal function to get the item at the specified index in the player-specific queue.
    /// @param user The address of the player whose queue is being accessed.
    /// @param index The index of the item to retrieve from the player-specific queue.
    /// @return waveId The waveId of the item at the specified index in the player-specific queue.
    /// @return quantity The quantity associated with the item at the specified index in the player-specific queue.
    function getPlayerQueueAtIndex(
        address user,
        uint256 index
    ) internal view returns (uint256 waveId, uint256 quantity) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        return playerQueue.at(index);
    }

    /// @dev Internal function to get the item at the specified index in the global queue.
    /// @param index The index of the item to retrieve from the global queue.
    /// @return waveId The waveId of the item at the specified index in the global queue.
    /// @return quantity The quantity associated with the item at the specified index in the global queue.
    function getGlobalQueueAtIndex(
        uint256 index
    )
        internal
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
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        return globalQueue.at(index);
    }

    /// @dev Internal function to retrieve the player-specific queue for the given user.
    /// @param user The address of the player whose queue is being accessed.
    /// @return waveIdsArray An array containing the waveIds of items in the player-specific queue.
    /// @return quantityArray An array containing the quantities associated with items in the player-specific queue.
    function getPlayerQueue(
        address user
    )
        internal
        view
        returns (uint256[] memory waveIdsArray, uint256[] memory quantityArray)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage queue = lrs.playerQueue[user];

        uint256 queueLen = queue.length();
        waveIdsArray = new uint256[](queueLen);
        quantityArray = new uint256[](queueLen);

        for (uint256 i = 0; i < queueLen; i++) {
            (uint256 waveId, uint256 quantity) = queue.at(i);
            waveIdsArray[i] = waveId;
            quantityArray[i] = quantity;
        }

        return (waveIdsArray, quantityArray);
    }

    /// @dev Internal function to retrieve the global queue.
    /// @return waveIdsArray An array containing the waveIds of items in the global queue.
    /// @return quantityArray An array containing the quantities associated with items in the global queue.
    function getGlobalQueue()
        internal
        view
        returns (uint256[] memory waveIdsArray, uint256[] memory quantityArray)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage queue = lrs.globalQueue;

        uint256 queueLen = queue.length();
        waveIdsArray = new uint256[](queueLen);
        quantityArray = new uint256[](queueLen);
        for (uint256 i = 0; i < queueLen; i++) {
            (uint256 waveId, uint256 quantity, , , , ) = queue.at(i);
            waveIdsArray[i] = waveId;
            quantityArray[i] = quantity;
        }

        return (waveIdsArray, quantityArray);
    }

    /// @dev Internal function to set the wave UNIM tokens available for rewards.
    /// @param _waveUNIM The new wave UNIM token value to be set.
    function setWaveUNIM(uint256 _waveUNIM) internal {
        rewardStorage().waveUNIM = _waveUNIM;
    }

    /// @dev Internal function to get the wave UNIM tokens available for rewards.
    /// @return waveUNIM The wave UNIM token value.
    function getWaveUNIM() internal view returns (uint256 waveUNIM) {
        return rewardStorage().waveUNIM;
    }

    /// @dev Internal function to set the wave Dark Marks available for rewards.
    /// @param _waveDarkMarks The new wave Dark Marks value to be set.
    function setWaveDarkMarks(uint256 _waveDarkMarks) internal {
        rewardStorage().waveDarkMarks = _waveDarkMarks;
    }

    /// @dev Internal function to get the wave Dark Marks available for rewards.
    /// @return waveDarkMarks The wave Dark Marks value.
    function getWaveDarkMarks() internal view returns (uint256 waveDarkMarks) {
        return rewardStorage().waveDarkMarks;
    }

    /// @dev Internal function to check if the player's queue is initialized.
    /// @param user The address of the player whose queue is to be checked.
    /// @return isInitialized True if the player's queue is initialized, false otherwise.
    function isPlayerQueueInitialized(
        address user
    ) internal view returns (bool isInitialized) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        return playerQueue.isInitialized();
    }

    /// @dev Internal function to check if the global queue is initialized.
    /// @return isInitialized True if the global queue is initialized, false otherwise.
    function isGlobalQueueInitialized()
        internal
        view
        returns (bool isInitialized)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;
        return globalQueue.isInitialized();
    }

    /// @notice Checks if the current reward wave has expired.
    /// @dev Returns true if the time elapsed since the last wave started is greater than or equal to the duration of a reward wave (24 hours).
    /// @return isExpired True if the current reward wave is expired, otherwise false.
    function isWaveExpired() internal view returns (bool isExpired) {
        LibRewardsStorage storage lrs = rewardStorage();
        return block.timestamp - lrs.waveTime >= LibTime.SECONDS_PER_DAY;
    }

    /// @notice Retrieves the wave rewards (UNIM and Dark Marks) from the global queue.
    /// @return waveUNIMArray An array containing the UNIM rewards for each wave in the global queue.
    /// @return waveDarkMarksArray An array containing the Dark Marks rewards for each wave in the global queue.
    function getGlobalQueueWaveRewards()
        internal
        view
        returns (
            uint256[] memory waveUNIMArray,
            uint256[] memory waveDarkMarksArray
        )
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage queue = lrs.globalQueue;

        uint256 queueLen = queue.length();
        waveUNIMArray = new uint256[](queueLen);
        waveDarkMarksArray = new uint256[](queueLen);
        for (uint256 i = 0; i < queueLen; i++) {
            (, , uint256 waveUNIM, uint256 waveDarkMarks, , ) = queue.at(i);
            waveUNIMArray[i] = waveUNIM;
            waveDarkMarksArray[i] = waveDarkMarks;
        }

        return (waveUNIMArray, waveDarkMarksArray);
    }

    /// @notice Retrieves the unclaimed rewards (UNIM and Dark Marks) from the global queue.
    /// @return unclaimedUnimArray An array containing the unclaimed UNIM for each wave in the global queue.
    /// @return unclaimedDarkmarksArray An array containing the unclaimed Dark Marks for each wave in the global queue.
    function getGlobalQueueUnclaimedRewards()
        internal
        view
        returns (
            uint256[] memory unclaimedUnimArray,
            uint256[] memory unclaimedDarkmarksArray
        )
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage queue = lrs.globalQueue;

        uint256 queueLen = queue.length();
        unclaimedUnimArray = new uint256[](queueLen);
        unclaimedDarkmarksArray = new uint256[](queueLen);

        for (uint256 i = 0; i < queueLen; i++) {
            (, , , , uint256 unclaimedUnim, uint256 unclaimedDarkmarks) = queue
                .at(i);
            unclaimedUnimArray[i] = unclaimedUnim;
            unclaimedDarkmarksArray[i] = unclaimedDarkmarks;
        }

        return (unclaimedUnimArray, unclaimedDarkmarksArray);
    }

    /// @notice Retrieves the claimable UNIM (Universal Incentive Mechanism) tokens for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the claimable UNIM.
    /// @return claimableUNIM The amount of claimable UNIM tokens for the specified wave ID.
    function getClaimableUNIM(
        uint256 waveId
    ) internal view returns (uint256 claimableUNIM) {
        return rewardStorage().globalQueue.getClaimableUNIM(waveId);
    }

    /// @notice Retrieves the claimable Dark Marks tokens for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the claimable Dark Marks.
    /// @return claimableDarkMarks The amount of claimable Dark Marks tokens for the specified wave ID.
    function getClaimableDarkMarks(
        uint256 waveId
    ) internal view returns (uint256 claimableDarkMarks) {
        return rewardStorage().globalQueue.getClaimableDarkMarks(waveId);
    }

    /// @notice Retrieves the UNIM tokens for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the UNIM tokens.
    /// @return waveUNIM The amount of UNIM tokens for the specified wave ID.
    function getWaveUNIMByWaveId(
        uint256 waveId
    ) internal view returns (uint256 waveUNIM) {
        return rewardStorage().globalQueue.getWaveUNIMByWaveId(waveId);
    }

    /// @notice Retrieves the Dark Marks for a given wave ID.
    /// @param waveId The wave ID for which to retrieve the Dark Marks.
    /// @return waveDarkMarks The amount of Dark Marks for the specified wave ID.
    function getWaveDarkMarksByWaveId(
        uint256 waveId
    ) internal view returns (uint256 waveDarkMarks) {
        return rewardStorage().globalQueue.getWaveDarkMarksByWaveId(waveId);
    }

    /// @dev Retrieves the total unclaimed rewards in the global queue.
    /// Iterates through the queue, summing the unclaimed UNIM and Darkmarks rewards.
    /// @return unclaimedUnim The total amount of unclaimed UNIM tokens.
    /// @return unclaimedDarkmarks The total amount of unclaimed Darkmarks.
    function getUnclaimedRewards()
        internal
        view
        returns (uint256 unclaimedUnim, uint256 unclaimedDarkmarks)
    {
        LibRewardsStorage storage lrs = rewardStorage();
        LibGlobalQueue.QueueStorage storage queue = lrs.globalQueue;

        uint256 queueLen = queue.length();
        for (uint256 i = 0; i < queueLen; i++) {
            (
                ,
                ,
                ,
                ,
                uint256 _unclaimedUnim,
                uint256 _unclaimedDarkmarks
            ) = queue.at(i);
            unclaimedUnim += _unclaimedUnim;
            unclaimedDarkmarks += _unclaimedDarkmarks;
        }

        return (unclaimedUnim, unclaimedDarkmarks);
    }

    /// @dev Retrieves the total distributed rewards.
    /// @return distributedUNIM The total amount of distributed UNIM tokens.
    /// @return distributedDarkMarks The total amount of distributed Darkmarks.
    function getDistributedRewards()
        internal
        view
        returns (uint256 distributedUNIM, uint256 distributedDarkMarks)
    {
        return (
            rewardStorage().distributedUNIM,
            rewardStorage().distributedDarkMarks
        );
    }

    /// @dev Calculates the contribution percentage of a specific user over the last 7 waves (including the current wave).
    /// It calculates the total contribution of a user in comparison to the global contributions.
    /// @param user The address of the user whose contribution percentage is being calculated.
    /// @return contributionPercentage The percentage of the user's contribution in the last 7 waves.
    function getContributionPercentage(
        address user
    ) internal view returns (uint256 contributionPercentage) {
        LibRewardsStorage storage lrs = rewardStorage();
        LibPlayerQueue.QueueStorage storage playerQueue = lrs.playerQueue[user];
        LibGlobalQueue.QueueStorage storage globalQueue = lrs.globalQueue;

        // get today's wave id
        (uint256 currentWaveCount, ) = calculateCurrentWaveData();

        uint256 startWaveId;
        if (currentWaveCount > 1) {
            startWaveId = currentWaveCount - 1;
        } else {
            startWaveId = 0;
        }

        uint256 endWaveId;
        if (currentWaveCount >= 7) {
            endWaveId = currentWaveCount - 7;
        } else {
            endWaveId = 0;
        }

        uint256 totalPlayerMinions;
        uint256 totalGlobalMinions;

        // loop from today's wave id back to the 6 waves before
        for (uint256 waveId = startWaveId; waveId > endWaveId; waveId--) {
            // check if wave id exists in both queues
            if (
                playerQueue.waveIdExistsInQueue(waveId) &&
                globalQueue.waveIdExistsInQueue(waveId)
            ) {
                // calculate player and global contribution
                totalPlayerMinions += playerQueue.getQtyByWaveId(waveId);
                totalGlobalMinions += globalQueue.getQtyByWaveId(waveId);
            }
        }

        if (totalGlobalMinions == 0) {
            return (0);
        }

        contributionPercentage =
            (totalPlayerMinions * 100) /
            totalGlobalMinions;

        return (contributionPercentage);
    }

    /// @notice Returns the daily UNIM rewards.
    /// @return dailyUNIM The quantity of UNIM allocated for the current wave.
    function getDailyUNIM() internal view returns (uint256 dailyUNIM) {
        (uint256 waveId, ) = calculateCurrentWaveData();
        dailyUNIM = getWaveUNIMByWaveId(waveId);
        if (dailyUNIM == 0) {
            dailyUNIM = getWaveUNIM();
        }
        return dailyUNIM;
    }

    /// @notice Returns the daily DarkMarks rewards.
    /// @return dailyDarkMarks The quantity of DarkMarks allocated for the current wave.
    function getDailyDarkMarks()
        internal
        view
        returns (uint256 dailyDarkMarks)
    {
        (uint256 waveId, ) = calculateCurrentWaveData();
        dailyDarkMarks = getWaveDarkMarksByWaveId(waveId);
        if (dailyDarkMarks == 0) {
            dailyDarkMarks = getWaveDarkMarks();
        }
        return dailyDarkMarks;
    }

    /// @notice Returns both the daily UNIM and DarkMarks rewards.
    /// @return dailyUNIM The quantity of UNIM allocated for the current wave.
    /// @return dailyDarkMarks The quantity of DarkMarks allocated for the current wave.
    function getDailyRewards()
        internal
        view
        returns (uint256 dailyUNIM, uint256 dailyDarkMarks)
    {
        return (getDailyUNIM(), getDailyDarkMarks());
    }

    /// @dev Retrieves the storage position for LibRewardsStorage using inline assembly.
    /// This function accesses the storage location associated with the constant REWARD_STORAGE_POSITION.
    /// @return lrs The reference to LibRewardsStorage structure in storage.
    function rewardStorage()
        internal
        pure
        returns (LibRewardsStorage storage lrs)
    {
        bytes32 position = REWARD_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            lrs.slot := position
        }
    }
}
