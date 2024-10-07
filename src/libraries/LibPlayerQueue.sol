// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title LibPlayerQueue
/// @author Shiva Shanmuganathan
/// @dev Implementation of the queue data structure, providing a library with struct definition for queue storage in consuming contracts.
/// @notice This library provides functionalities to manage a queue data structure, allowing contracts to enqueue and dequeue items.
library LibPlayerQueue {
    struct QueueStorage {
        mapping(uint256 idx => uint256 waveId) idxToWaveId;
        mapping(uint256 waveId => uint256 quantity) waveIdToQty;
        uint256 first;
        uint256 last;
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
    function enqueue(QueueStorage storage queue, uint256 waveId, uint256 quantity) internal {
        enforceQueueInitialized(queue);
        queue.idxToWaveId[++queue.last] = waveId;
        queue.waveIdToQty[waveId] = quantity;
    }

    /// @dev Dequeues an item from the front of the queue.
    /// @param queue The queue to dequeue an item from.
    /// @return waveId The waveId of the dequeued item.
    /// @return quantity The quantity associated with the dequeued item.
    function dequeue(QueueStorage storage queue) internal returns (uint256 waveId, uint256 quantity) {
        enforceQueueInitialized(queue);
        enforceNonEmptyQueue(queue);

        waveId = queue.idxToWaveId[queue.first];
        quantity = queue.waveIdToQty[waveId];

        delete queue.waveIdToQty[waveId];
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
        require(queue.idxToWaveId[queue.last] == waveId, 'LibPlayerQueue: Wave does not exist in Player Queue.');
        queue.waveIdToQty[waveId] += quantity;
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
        require(isInitialized(queue), 'LibPlayerQueue: Queue is not initialized.');
    }

    /// @dev Function to check if the queue is not empty.
    /// @param queue The queue to check.
    function enforceNonEmptyQueue(QueueStorage storage queue) internal view {
        require(!isEmpty(queue), 'LibPlayerQueue: Queue is empty.');
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
    function peek(QueueStorage storage queue) internal view returns (uint256 waveId, uint256 quantity) {
        enforceNonEmptyQueue(queue);
        waveId = queue.idxToWaveId[queue.first];
        quantity = queue.waveIdToQty[waveId];
    }

    /// @dev Returns the item at the end of the queue without dequeuing it.
    /// @param queue The queue to get the last item from.
    /// @return waveId The waveId of the last item.
    /// @return quantity The quantity associated with the last item.
    function peekLast(QueueStorage storage queue) internal view returns (uint256 waveId, uint256 quantity) {
        enforceNonEmptyQueue(queue);
        waveId = queue.idxToWaveId[queue.last];
        quantity = queue.waveIdToQty[waveId];
    }

    /// @dev Returns the item at the given index in the queue.
    /// @param queue The queue to get the item from.
    /// @param idx The index of the item to retrieve.
    /// @return waveId The waveId of the item at the given index.
    /// @return quantity The quantity associated with the item at the given index.
    function at(QueueStorage storage queue, uint256 idx) internal view returns (uint256 waveId, uint256 quantity) {
        idx = idx + queue.first;
        waveId = queue.idxToWaveId[idx];
        quantity = queue.waveIdToQty[waveId];
    }

    /// @notice Checks if a given wave ID exists in the specified queue.
    /// @param queue The storage reference to the queue being checked.
    /// @param waveId The wave ID to check for existence in the queue.
    /// @return waveExists A boolean value indicating whether the specified wave ID exists in the queue.
    function waveIdExistsInQueue(QueueStorage storage queue, uint256 waveId) internal view returns (bool waveExists) {
        if (queue.waveIdToQty[waveId] == 0) {
            return false;
        }
        return true;
    }

    /// @notice Retrieves the quantity associated with a given wave ID in the specified queue.
    /// @param queue The storage reference to the queue from which the quantity is being retrieved.
    /// @param waveId The wave ID for which the quantity is being fetched.
    /// @return quantity The quantity associated with the specified wave ID.
    function getQtyByWaveId(QueueStorage storage queue, uint256 waveId) internal view returns (uint256 quantity) {
        return queue.waveIdToQty[waveId];
    }

    /// @notice Calculates the number of elements that can be dequeued from the provided queue based on the given wave ID.
    /// @dev This function checks the last element in the queue to determine how many elements can be dequeued.
    ///      The dequeuing logic is dependent on whether the last wave ID in the queue matches the given wave ID.
    /// @param queue The storage reference to the queue from which the dequeue count is being calculated.
    /// @param waveId The wave ID used as the reference point for calculating the dequeue count.
    /// @return dequeueCount The calculated number of elements that can be dequeued from the queue.
    function getDequeueCount(QueueStorage storage queue, uint256 waveId) internal view returns (uint256 dequeueCount) {
        uint256 queueLen = length(queue);
        (uint256 waveIdFromQueue, ) = peekLast(queue);
        if (waveIdFromQueue == waveId) {
            dequeueCount = queueLen - 1;
        } else {
            dequeueCount = queueLen;
        }
        return dequeueCount;
    }
}
