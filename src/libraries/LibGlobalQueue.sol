// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title LibGlobalQueue
/// @author Shiva Shanmuganathan
/// @dev Implementation of the queue data structure, providing a library with struct definition for queue storage in consuming contracts.
/// @notice This library provides functionalities to manage a queue data structure, allowing contracts to enqueue and dequeue items.
library LibGlobalQueue {
    struct QueueStorage {
        mapping(uint256 idx => uint256 waveId) idxToWaveId;
        mapping(uint256 waveId => TxData txData) waveIdToTxData;
        uint256 first;
        uint256 last;
    }

    // NOTE: This structure is a STORAGE STRUCT (used in storage), modifying it can have significant implications.
    // Please exercise caution and avoid modifying this structure unless absolutely necessary.
    struct TxData {
        uint256 quantity;
        uint256 waveUNIM;
        uint256 waveDarkMarks;
        uint256 unclaimedUnim;
        uint256 unclaimedDarkmarks;
    }

    /// @dev Initializes the queue by setting the first and last indices.
    /// @param queue The queue to initialize.
    function initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    /// @dev Enqueues a new item into the queue.
    /// @param queue The queue to enqueue the item into.
    /// @param waveId The waveId of the item.
    /// @param quantity The quantity associated with the item.
    /// @param waveUNIM The unim pool associated with the item.
    /// @param waveDarkMarks The darkmarks pool associated with the item.
    /// @param unclaimedUnim The unclaimed unim associated with the item.
    /// @param unclaimedDarkmarks The unclaimed darkmarks associated with the item.
    function enqueue(
        QueueStorage storage queue,
        uint256 waveId,
        uint256 quantity,
        uint256 waveUNIM,
        uint256 waveDarkMarks,
        uint256 unclaimedUnim,
        uint256 unclaimedDarkmarks
    ) internal {
        enforceQueueInitialized(queue);
        queue.idxToWaveId[++queue.last] = waveId;
        queue.waveIdToTxData[waveId] = TxData(quantity, waveUNIM, waveDarkMarks, unclaimedUnim, unclaimedDarkmarks);
    }

    /// @dev Dequeues an item from the front of the queue.
    /// @param queue The queue to dequeue an item from.
    /// @return waveId The waveId of the dequeued item.
    /// @return quantity The quantity associated with the dequeued item.
    /// @return waveUNIM The unim pool associated with the dequeued item.
    /// @return waveDarkMarks The darkmarks pool associated with the dequeued item.
    /// @return unclaimedUnim The unclaimed unim associated with the dequeued item.
    /// @return unclaimedDarkmarks The unclaimed darkmarks associated with the dequeued item.
    function dequeue(
        QueueStorage storage queue
    )
        internal
        returns (
            uint256 waveId,
            uint256 quantity,
            uint256 waveUNIM,
            uint256 waveDarkMarks,
            uint256 unclaimedUnim,
            uint256 unclaimedDarkmarks
        )
    {
        enforceQueueInitialized(queue);
        enforceNonEmptyQueue(queue);
        waveId = queue.idxToWaveId[queue.first];
        TxData memory txData = queue.waveIdToTxData[waveId];
        quantity = txData.quantity;
        waveUNIM = txData.waveUNIM;
        waveDarkMarks = txData.waveDarkMarks;
        unclaimedUnim = txData.unclaimedUnim;
        unclaimedDarkmarks = txData.unclaimedDarkmarks;

        delete queue.waveIdToTxData[waveId];
        delete queue.idxToWaveId[queue.first];
        queue.first = queue.first + 1;
    }

    /// @notice Updates the quantity of rewards associated with a given wave ID in the queue.
    /// @dev Ensures that the specified wave ID matches the last wave ID in the queue.
    /// @param queue The storage reference to the queue being updated.
    /// @param waveId The wave ID for which the quantity is being updated.
    /// @param quantity The amount to add to the existing quantity associated with the wave ID.
    /// require The specified wave ID must match the last wave ID in the queue.
    function updateQty(QueueStorage storage queue, uint256 waveId, uint256 quantity) internal {
        require(queue.idxToWaveId[queue.last] == waveId, 'LibGlobalQueue: Wave does not exist in Global Queue.');
        queue.waveIdToTxData[waveId].quantity += quantity;
    }

    /// @notice Deducts the claimed UNIM and Dark Marks rewards for a specific wave ID in the provided queue.
    /// @dev This function updates the unclaimed rewards within the queue's transaction data, reducing them by the amounts claimed.
    /// @param queue The storage reference to the queue where the claimed rewards are being deducted.
    /// @param waveId The wave ID for which the rewards are being deducted.
    /// @param claimedUnim The amount of UNIM rewards that have been claimed and should be deducted.
    /// @param claimedDarkmarks The amount of Dark Marks rewards that have been claimed and should be deducted.
    function deductClaimedRewards(
        QueueStorage storage queue,
        uint256 waveId,
        uint256 claimedUnim,
        uint256 claimedDarkmarks
    ) internal {
        TxData storage txData = queue.waveIdToTxData[waveId];
        txData.unclaimedUnim -= claimedUnim;
        txData.unclaimedDarkmarks -= claimedDarkmarks;
    }

    /// @dev Checks if the queue has been initialized.
    /// @param queue The queue to check.
    /// @return isQueueInitialized True if the queue is initialized, false otherwise.
    function isInitialized(QueueStorage storage queue) internal view returns (bool isQueueInitialized) {
        return queue.first != 0;
    }

    /// @dev Checks if the queue is initialized and raises an error if not.
    /// @param queue The queue to check for initialization.
    function enforceQueueInitialized(QueueStorage storage queue) internal view {
        require(isInitialized(queue), 'LibGlobalQueue: Queue is not initialized.');
    }

    /// @dev Function to check if the queue is not empty.
    /// @param queue The queue to check.
    function enforceNonEmptyQueue(QueueStorage storage queue) internal view {
        require(!isEmpty(queue), 'LibGlobalQueue: Queue is empty.');
    }

    /// @dev Returns the length of the queue.
    /// @param queue The queue to get the length of.
    /// @return queueLength The length of the queue.
    function length(QueueStorage storage queue) internal view returns (uint256 queueLength) {
        if (queue.last < queue.first) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    /// @dev Checks if the queue is empty.
    /// @param queue The queue to check.
    /// @return isQueueEmpty True if the queue is empty, false otherwise.
    function isEmpty(QueueStorage storage queue) internal view returns (bool isQueueEmpty) {
        return length(queue) == 0;
    }

    /// @dev Returns the item at the front of the queue without dequeuing it.
    /// @param queue The queue to get the front item from.
    /// @return waveId The waveId of the front item.
    /// @return quantity The quantity associated with the front item.
    /// @return waveUNIM The unim pool associated with the front item.
    /// @return waveDarkMarks The darkmarks pool associated with the front item.
    /// @return unclaimedUnim The unclaimed unim associated with the front item.
    /// @return unclaimedDarkmarks The unclaimed darkmarks associated with the front item.
    function peek(
        QueueStorage storage queue
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
        waveId = queue.idxToWaveId[queue.first];
        TxData memory txData = queue.waveIdToTxData[waveId];
        quantity = txData.quantity;
        waveUNIM = txData.waveUNIM;
        waveDarkMarks = txData.waveDarkMarks;
        unclaimedUnim = txData.unclaimedUnim;
        unclaimedDarkmarks = txData.unclaimedDarkmarks;
    }

    /// @dev Returns the item at the end of the queue without dequeuing it.
    /// @param queue The queue to get the last item from.
    /// @return waveId The waveId of the last item.
    /// @return quantity The quantity associated with the last item.
    /// @return waveUNIM The unim pool associated with the last item.
    /// @return waveDarkMarks The darkmarks pool associated with the last item.
    /// @return unclaimedUnim The unclaimed unim associated with the last item.
    /// @return unclaimedDarkmarks The unclaimed darkmarks associated with the last item.
    function peekLast(
        QueueStorage storage queue
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
        waveId = queue.idxToWaveId[queue.last];
        TxData memory txData = queue.waveIdToTxData[waveId];
        quantity = txData.quantity;
        waveUNIM = txData.waveUNIM;
        waveDarkMarks = txData.waveDarkMarks;
        unclaimedUnim = txData.unclaimedUnim;
        unclaimedDarkmarks = txData.unclaimedDarkmarks;
    }

    /// @dev Returns the item at the given index in the queue.
    /// @param queue The queue to get the item from.
    /// @param idx The index of the item to retrieve.
    /// @return waveId The waveId of the item at the given index.
    /// @return quantity The quantity associated with the item at the given index.
    /// @return waveUNIM The unim pool associated with the item at the given index.
    /// @return waveDarkMarks The darkmarks pool associated with the item at the given index.
    /// @return unclaimedUnim The unclaimed unim associated with the item at the given index.
    /// @return unclaimedDarkmarks The unclaimed darkmarks associated with the item at the given index.
    function at(
        QueueStorage storage queue,
        uint256 idx
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
        idx = idx + queue.first;
        waveId = queue.idxToWaveId[idx];
        TxData memory txData = queue.waveIdToTxData[waveId];
        quantity = txData.quantity;
        waveUNIM = txData.waveUNIM;
        waveDarkMarks = txData.waveDarkMarks;
        unclaimedUnim = txData.unclaimedUnim;
        unclaimedDarkmarks = txData.unclaimedDarkmarks;
    }

    /// @notice Checks if a given wave ID exists in the specified queue.
    /// @param queue The storage reference to the queue being checked.
    /// @param waveId The wave ID to check for existence in the queue.
    /// @return waveExists A boolean value indicating whether the specified wave ID exists in the queue.
    function waveIdExistsInQueue(QueueStorage storage queue, uint256 waveId) internal view returns (bool waveExists) {
        if (queue.waveIdToTxData[waveId].quantity == 0) {
            return false;
        }
        return true;
    }

    /// @notice Retrieves the quantity associated with a given wave ID in the specified queue.
    /// @param queue The storage reference to the queue from which the quantity is being retrieved.
    /// @param waveId The wave ID for which the quantity is being fetched.
    /// @return quantity The quantity associated with the specified wave ID.
    function getQtyByWaveId(QueueStorage storage queue, uint256 waveId) internal view returns (uint256 quantity) {
        return queue.waveIdToTxData[waveId].quantity;
    }

    /// @dev Returns the dequeue count for waves more than 7 days old (or 7 waves ago) from the provided waveId.
    /// @param queue The queue to get the dequeue count from.
    /// @param waveId The waveId from which to count older waves.
    /// @return dequeueCount The count of waves more than 7 days old.
    function getDequeueCount(QueueStorage storage queue, uint256 waveId) internal view returns (uint256) {
        uint256 dequeueCount = 0;
        uint256 waveIdFromQueue;

        // If queue length is 0, there's nothing to dequeue.
        if (length(queue) == 0) {
            return 0;
        }

        // Loop over the queue from the end to the beginning.
        for (uint256 i = 0; i < length(queue); i++) {
            // Get the waveIdFromQueue at index i
            (waveIdFromQueue, , , , , ) = at(queue, i);

            // If the waveIdFromQueue is more than 7 days old, increment dequeueCount and continue.
            if (waveId - 6 > waveIdFromQueue) {
                dequeueCount++;
            } else {
                // If the waveIdFromQueue is within 7 days, break the loop.
                break;
            }
        }

        return dequeueCount;
    }

    /// @notice Checks if the queue has any waves that are considered outdated based on the given wave ID.
    /// @param queue The storage reference to the queue being checked.
    /// @param waveId The wave ID used to determine if there are any outdated waves in the queue.
    /// @return waveExists A boolean value indicating whether there are outdated waves in the queue.
    function hasOutdatedWaves(QueueStorage storage queue, uint256 waveId) internal view returns (bool waveExists) {
        (uint256 waveIdFromQueueStart, , , , , ) = peek(queue);
        if (waveId - waveIdFromQueueStart + 1 > 7) {
            return true;
        }
        return false;
    }

    /// @notice Calculates the total unclaimed rewards in UNIM and DarkMarks for outdated waves in the queue.
    /// @param queue The storage reference to the queue being examined.
    /// @param waveId The wave ID used to determine if there are any outdated waves in the queue.
    /// @return totalUnclaimedUNIM The total unclaimed rewards in UNIM for the outdated waves.
    /// @return totalUnclaimedDarkMarks The total unclaimed rewards in DarkMarks for the outdated waves.
    function getUnclaimedRewardsInQueue(
        QueueStorage storage queue,
        uint256 waveId
    ) internal view returns (uint256 totalUnclaimedUNIM, uint256 totalUnclaimedDarkMarks) {
        for (uint256 i = 0; i < length(queue); i++) {
            (uint256 waveIdFromQueue, , , , uint256 unclaimedUnim, uint256 unclaimedDarkmarks) = at(queue, i);
            if (waveId - 6 > waveIdFromQueue) {
                totalUnclaimedUNIM += (unclaimedUnim);
                totalUnclaimedDarkMarks += (unclaimedDarkmarks);
            } else {
                break;
            }
        }
        return (totalUnclaimedUNIM, totalUnclaimedDarkMarks);
    }

    /// @notice Retrieves the claimable UNIM reward for a given wave ID from the queue.
    /// @param queue The storage reference to the queue being examined.
    /// @param waveId The wave ID for which the claimable UNIM is being retrieved.
    /// @return claimableUNIM The amount of claimable UNIM for the specified wave ID.
    function getClaimableUNIM(
        QueueStorage storage queue,
        uint256 waveId
    ) internal view returns (uint256 claimableUNIM) {
        return queue.waveIdToTxData[waveId].unclaimedUnim;
    }

    /// @notice Retrieves the claimable DarkMarks reward for a given wave ID from the queue.
    /// @param queue The storage reference to the queue being examined.
    /// @param waveId The wave ID for which the claimable DarkMarks is being retrieved.
    /// @return claimableDarkMarks The amount of claimable DarkMarks for the specified wave ID.
    function getClaimableDarkMarks(
        QueueStorage storage queue,
        uint256 waveId
    ) internal view returns (uint256 claimableDarkMarks) {
        return queue.waveIdToTxData[waveId].unclaimedDarkmarks;
    }

    /// @notice Retrieves the UNIM rewards associated with a given wave ID in the specified queue.
    /// @param queue The storage reference to the queue from which the UNIM rewards are being retrieved.
    /// @param waveId The wave ID for which the UNIM rewards are being fetched.
    /// @return waveUNIM The UNIM rewards associated with the specified wave ID.
    function getWaveUNIMByWaveId(QueueStorage storage queue, uint256 waveId) internal view returns (uint256 waveUNIM) {
        return queue.waveIdToTxData[waveId].waveUNIM;
    }

    /// @notice Retrieves the Dark Marks rewards associated with a given wave ID in the specified queue.
    /// @param queue The storage reference to the queue from which the Dark Marks rewards are being retrieved.
    /// @param waveId The wave ID for which the Dark Marks rewards are being fetched.
    /// @return waveDarkMarks The Dark Marks rewards associated with the specified wave ID.
    function getWaveDarkMarksByWaveId(
        QueueStorage storage queue,
        uint256 waveId
    ) internal view returns (uint256 waveDarkMarks) {
        return queue.waveIdToTxData[waveId].waveDarkMarks;
    }
}
