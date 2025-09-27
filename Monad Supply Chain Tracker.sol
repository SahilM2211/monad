// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MonadSupplyChainTracker
 * @author [Your Name]
 * @notice A smart contract for tracking items through a supply chain on Monad.
 * This contract leverages Monad's high throughput to handle a large volume of updates
 * for many items in parallel, solving real-world issues of counterfeiting and lack of transparency.
 */
contract MonadSupplyChainTracker is Ownable, ReentrancyGuard {

    // --- Events ---
    event ItemCreated(uint256 indexed itemId, string name, address indexed initialCustodian);
    event CustodyTransferred(uint256 indexed itemId, address indexed from, address indexed to);
    event StatusUpdated(uint256 indexed itemId, uint8 newStatus, address indexed updatedBy);

    // --- Enums and Structs ---

    // Defines the possible states of an item in the supply chain.
    enum ItemStatus { Created, InTransit, InWarehouse, ReadyForSale, Sold, CounterfeitReported }

    // Represents a single event in an item's history.
    struct HistoryEvent {
        uint256 timestamp;
        address custodian;
        ItemStatus status;
        string location; // Optional metadata like a city or warehouse name
    }

    // The core object representing a trackable item.
    struct Item {
        uint256 id;
        string name;
        address currentCustodian;
        ItemStatus currentStatus;
        HistoryEvent[] history;
    }

    // --- State Variables ---

    mapping(uint256 => Item) public items;
    uint256 private nextItemId = 1;

    // --- Modifiers ---

    /**
     * @dev Throws if the caller is not the current custodian of the specified item.
     */
    modifier onlyCustodian(uint256 _itemId) {
        require(items[_itemId].currentCustodian == msg.sender, "Caller is not the current custodian");
        _;
    }

    /**
     * @dev Throws if the item ID does not exist.
     */
    modifier itemExists(uint256 _itemId) {
        require(items[_itemId].id != 0, "Item does not exist");
        _;
    }

    constructor() Ownable(msg.sender) {}

    // --- Functions ---

    /**
     * @notice Creates a new item and registers it in the supply chain.
     * @dev Can only be called by the contract owner (the "manufacturer").
     * @param _name The name or description of the item (e.g., "SKU: XYZ-123").
     */
    function createItem(string memory _name) external onlyOwner {
        uint256 itemId = nextItemId++;
        
        // Get a direct pointer to the new item's location in storage.
        Item storage newItem = items[itemId];
        
        // Assign the simple values directly to the storage struct.
        newItem.id = itemId;
        newItem.name = _name;
        newItem.currentCustodian = msg.sender;
        newItem.currentStatus = ItemStatus.Created;

        // The 'history' array is created empty by default.
        // Now, push the first event into it.
        newItem.history.push(HistoryEvent({
            timestamp: block.timestamp,
            custodian: msg.sender,
            status: ItemStatus.Created,
            location: "Factory"
        }));

        emit ItemCreated(itemId, _name, msg.sender);
    }

    /**
     * @notice Transfers custody of an item to a new party (e.g., shipper, retailer).
     * @dev Can only be called by the item's current custodian.
     * @param _itemId The ID of the item to transfer.
     * @param _newCustodian The address of the new custodian.
     * @param _location A string describing the new location (e.g., "Shipping Port LAX").
     */
    function transferCustody(uint256 _itemId, address _newCustodian, string memory _location) external itemExists(_itemId) onlyCustodian(_itemId) nonReentrant {
        require(_newCustodian != address(0), "New custodian cannot be the zero address");

        Item storage item = items[_itemId];
        address previousCustodian = item.currentCustodian;
        item.currentCustodian = _newCustodian;
        item.currentStatus = ItemStatus.InTransit;

        // Add a new event to the item's history log.
        item.history.push(HistoryEvent({
            timestamp: block.timestamp,
            custodian: _newCustodian,
            status: ItemStatus.InTransit,
            location: _location
        }));

        emit CustodyTransferred(_itemId, previousCustodian, _newCustodian);
        emit StatusUpdated(_itemId, uint8(ItemStatus.InTransit), _newCustodian);
    }

    /**
     * @notice Updates the status of an item.
     * @dev Can only be called by the item's current custodian.
     * Example: A retailer receives an item (`InTransit` -> `ReadyForSale`).
     * @param _itemId The ID of the item to update.
     * @param _newStatus The new status of the item.
     * @param _location A string describing the location of this status update.
     */
    function updateItemStatus(uint256 _itemId, ItemStatus _newStatus, string memory _location) external itemExists(_itemId) onlyCustodian(_itemId) nonReentrant {
    Item storage item = items[_itemId];
    item.currentStatus = _newStatus;  // ✅ Corrected

    item.history.push(HistoryEvent({
        timestamp: block.timestamp,
        custodian: msg.sender,
        status: _newStatus,
        location: _location
    }));

    emit StatusUpdated(_itemId, uint8(_newStatus), msg.sender);  // ✅ Corrected
}

    // --- View Functions ---

    /**
     * @notice Retrieves the full history of an item.
     * @param _itemId The ID of the item to query.
     * @return The array of historical events for the item.
     */
    function getItemHistory(uint256 _itemId) external view itemExists(_itemId) returns (HistoryEvent[] memory) {
        return items[_itemId].history;
    }

    /**
     * @notice Retrieves the current details of an item.
     * @param _itemId The ID of the item to query.
     * @return name The item's name.
     * @return currentCustodian The item's current custodian address.
     * @return currentStatus The item's current status.
     */
    function getCurrentDetails(uint256 _itemId) external view itemExists(_itemId) returns (string memory name, address currentCustodian, ItemStatus currentStatus) {
        Item storage item = items[_itemId];
        return (item.name, item.currentCustodian, item.currentStatus);
    }
}

