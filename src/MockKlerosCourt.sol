// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Mock Kleros Court Implementation
 * @author W3HC
 * @notice A simplified mock implementation of Kleros arbitration system for testing and development
 * @dev This contract simulates the basic functionality of Kleros court for dispute resolution.
 *      In production, this would be replaced with the actual Kleros arbitration contracts.
 *
 *      Ruling codes:
 *      - 0: No ruling yet / Pending
 *      - 1: Ruling in favor of first party (no violation)
 *      - 2: Ruling in favor of second party (violation confirmed)
 *
 * @custom:warning This is a mock contract for testing purposes only
 */
contract MockKlerosCourt {
    /// @notice Mapping of dispute IDs to their rulings
    /// @dev Stores the ruling decision for each dispute created
    ///      0 = no ruling, 1 = no violation, 2 = violation confirmed
    mapping(uint256 => uint256) public rulings;

    /// @notice Counter for generating unique dispute IDs
    /// @dev Incremented for each new dispute created
    uint256 public disputeCounter;

    /**
     * @notice Emitted when a new dispute is created
     * @param disputeID The unique identifier for the created dispute
     * @param creator The address that created the dispute
     */
    event DisputeCreated(uint256 indexed disputeID, address indexed creator);

    /**
     * @notice Emitted when a ruling is given for a dispute
     * @param disputeID The unique identifier of the dispute
     * @param ruling The ruling decision (0=pending, 1=no violation, 2=violation confirmed)
     * @param ruler The address that provided the ruling
     */
    event Ruling(
        uint256 indexed disputeID,
        uint256 ruling,
        address indexed ruler
    );

    /**
     * @notice Creates a new dispute in the arbitration system
     * @dev Increments the dispute counter and returns a unique dispute ID
     *      In a real Kleros implementation, this would involve staking tokens and jury selection
     * @return disputeID The unique identifier for the newly created dispute
     */
    function createDispute() external returns (uint256 disputeID) {
        disputeCounter++;
        disputeID = disputeCounter;

        emit DisputeCreated(disputeID, msg.sender);

        return disputeID;
    }

    /**
     * @notice Provides a ruling for a specific dispute
     * @dev In a real Kleros system, this would be done by selected jurors through a voting mechanism
     *      This mock allows any address to set rulings for testing purposes
     * @param _disputeID The unique identifier of the dispute to rule on
     * @param _ruling The ruling decision:
     *                0 = No ruling/Pending
     *                1 = No violation (ruling against the reporter)
     *                2 = Violation confirmed (ruling against the accused)
     */
    function giveRuling(uint256 _disputeID, uint256 _ruling) external {
        require(
            _disputeID > 0 && _disputeID <= disputeCounter,
            "Invalid dispute ID"
        );
        require(_ruling <= 2, "Invalid ruling value");

        rulings[_disputeID] = _ruling;

        emit Ruling(_disputeID, _ruling, msg.sender);
    }

    /**
     * @notice Retrieves the current ruling for a specific dispute
     * @dev Returns the ruling decision for the given dispute ID
     * @param _disputeID The unique identifier of the dispute to query
     * @return The current ruling for the dispute:
     *         0 = No ruling yet/Pending
     *         1 = No violation found
     *         2 = Violation confirmed
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256) {
        return rulings[_disputeID];
    }

    /**
     * @notice Checks if a dispute exists
     * @dev Verifies that a dispute ID is valid (has been created)
     * @param _disputeID The dispute ID to check
     * @return True if the dispute exists, false otherwise
     */
    function disputeExists(uint256 _disputeID) external view returns (bool) {
        return _disputeID > 0 && _disputeID <= disputeCounter;
    }

    /**
     * @notice Gets the total number of disputes created
     * @dev Returns the current value of the dispute counter
     * @return The total number of disputes that have been created
     */
    function getDisputeCount() external view returns (uint256) {
        return disputeCounter;
    }

    /**
     * @notice Checks if a dispute has been ruled upon
     * @dev A dispute is considered ruled if it has a non-zero ruling
     * @param _disputeID The dispute ID to check
     * @return True if the dispute has been ruled upon, false otherwise
     */
    function isDisputeRuled(uint256 _disputeID) external view returns (bool) {
        require(
            _disputeID > 0 && _disputeID <= disputeCounter,
            "Invalid dispute ID"
        );
        return rulings[_disputeID] != 0;
    }
}
