// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MonadLimitOrderBook
 * @author [Your Name]
 * @notice A simple on-chain limit order book exchange.
 * This contract is designed to be deployed on the Monad testnet.
 * It allows users to create limit buy and sell orders for a specific ERC20 token pair.
 */
contract MonadLimitOrderBook is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Events ---
    event OrderCreated(
        uint256 orderId,
        address indexed user,
        address indexed tokenGive,
        uint256 amountGive,
        address indexed tokenGet,
        uint256 amountGet,
        uint256 price
    );
    event OrderCancelled(uint256 orderId, address indexed user);
    event OrderFilled(
        uint256 orderId,
        address indexed user,
        address indexed filledBy,
        uint256 amountGiven,
        uint256 amountReceived
    );

    // --- State Variables ---
    struct Order {
        uint256 id;
        address user;
        address tokenGive;
        uint256 amountGive;
        address tokenGet;
        uint256 amountGet;
        uint256 price; // For simplicity, price is amountGet / amountGive
    }

    // We use two arrays to store buy and sell orders.
    // For a real-world application, a more sophisticated data structure would be used.
    Order[] public buyOrders;
    Order[] public sellOrders;

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;
    mapping(address => uint256) public userOrderCount;

    // The two tokens that can be traded on this exchange.
    IERC20 public immutable token1;
    IERC20 public immutable token2;

    // --- Constructor ---
    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }

    // --- Functions ---

    /**
     * @notice Creates a new limit order.
     * @param tokenGive The token the user wants to sell.
     * @param amountGive The amount of the token the user wants to sell.
     * @param tokenGet The token the user wants to buy.
     * @param amountGet The amount of the token the user wants to buy.
     */
    function createOrder(
        address tokenGive,
        uint256 amountGive,
        address tokenGet,
        uint256 amountGet
    ) external nonReentrant {
        require(
            (tokenGive == address(token1) && tokenGet == address(token2)) ||
            (tokenGive == address(token2) && tokenGet == address(token1)),
            "Invalid token pair"
        );
        require(amountGive > 0 && amountGet > 0, "Amounts must be positive");

        // Transfer tokens from the user to the contract
        IERC20(tokenGive).safeTransferFrom(msg.sender, address(this), amountGive);

        uint256 orderId = nextOrderId++;
        uint256 price = (amountGet * 1e18) / amountGive;

        Order memory newOrder = Order({
            id: orderId,
            user: msg.sender,
            tokenGive: tokenGive,
            amountGive: amountGive,
            tokenGet: tokenGet,
            amountGet: amountGet,
            price: price
        });

        orders[orderId] = newOrder;
        userOrderCount[msg.sender]++;

        // For simplicity, we just add to the end of the array.
        // A real implementation would keep the arrays sorted by price.
        if (tokenGive == address(token1)) {
            sellOrders.push(newOrder);
        } else {
            buyOrders.push(newOrder);
        }

        emit OrderCreated(orderId, msg.sender, tokenGive, amountGive, tokenGet, amountGet, price);
    }

    /**
     * @notice Matches and fills compatible buy and sell orders.
     * This function can be called by anyone to facilitate trades.
     */
    function matchOrders() external nonReentrant {
        // This is a simplified matching engine. A real one would be more complex.
        for (uint i = 0; i < buyOrders.length; i++) {
            for (uint j = 0; j < sellOrders.length; j++) {
                Order storage buyOrder = buyOrders[i];
                Order storage sellOrder = sellOrders[j];

                // Check if orders are still valid
                if (buyOrder.amountGive == 0 || sellOrder.amountGive == 0) {
                    continue;
                }

                // Check if prices are compatible (buy price >= sell price)
                if (buyOrder.price >= sellOrder.price) {
                    // For simplicity, we'll do a full fill of the smaller order
                    uint256 amountToFill = buyOrder.amountGive < sellOrder.amountGive
                        ? buyOrder.amountGive
                        : sellOrder.amountGive;

                    // Calculate amounts to be exchanged
                    uint256 amountToReceive = (amountToFill * sellOrder.price) / 1e18;

                    // Update order amounts
                    buyOrder.amountGive -= amountToFill;
                    sellOrder.amountGive -= amountToFill;
                    buyOrder.amountGet -= amountToReceive;
                    sellOrder.amountGet -= amountToReceive;

                    // Transfer tokens
                    IERC20(buyOrder.tokenGive).safeTransfer(sellOrder.user, amountToFill);
                    IERC20(sellOrder.tokenGive).safeTransfer(buyOrder.user, amountToReceive);

                    emit OrderFilled(buyOrder.id, buyOrder.user, sellOrder.user, amountToFill, amountToReceive);
                    emit OrderFilled(sellOrder.id, sellOrder.user, buyOrder.user, amountToReceive, amountToFill);

                    // If an order is fully filled, remove it.
                    if (buyOrder.amountGive == 0) {
                        _removeOrder(i, true);
                    }
                    if (sellOrder.amountGive == 0) {
                        _removeOrder(j, false);
                    }
                }
            }
        }
    }

    /**
     * @notice Cancels an open order.
     * @param orderId The ID of the order to cancel.
     */
    function cancelOrder(uint256 orderId) external nonReentrant {
        Order storage orderToCancel = orders[orderId];
        require(orderToCancel.user == msg.sender, "Not your order");
        require(orderToCancel.amountGive > 0, "Order already filled");

        // Transfer the remaining tokens back to the user
        IERC20(orderToCancel.tokenGive).safeTransfer(msg.sender, orderToCancel.amountGive);

        // Mark the order as cancelled
        orderToCancel.amountGive = 0;
        userOrderCount[msg.sender]--;

        emit OrderCancelled(orderId, msg.sender);
    }

    // --- Helper Functions ---

    /**
     * @notice Removes an order from the buy or sell array.
     * @param index The index of the order to remove.
     * @param isBuyOrder True if the order is in the buyOrders array, false otherwise.
     */
    function _removeOrder(uint256 index, bool isBuyOrder) private {
        if (isBuyOrder) {
            buyOrders[index] = buyOrders[buyOrders.length - 1];
            buyOrders.pop();
        } else {
            sellOrders[index] = sellOrders[sellOrders.length - 1];
            sellOrders.pop();
        }
    }
}
