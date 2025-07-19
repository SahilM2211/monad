// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirectTokenVault is Ownable {
    IERC20 public immutable token;

    struct Deposit {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Deposit) public userDeposits;
    event DepositReceived(address indexed from, uint256 amount, uint256 unlockAt);
    event TokensWithdrawn(address indexed user, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    // Called by user after directly transferring tokens to contract
    function registerDeposit(uint256 amount, uint256 lockDurationSeconds) external {
        require(amount > 0, "Amount must be > 0");
        require(token.balanceOf(address(this)) >= amount, "Contract doesn't have the tokens");
        require(userDeposits[msg.sender].amount == 0, "Already deposited");

        userDeposits[msg.sender] = Deposit({
            amount: amount,
            unlockTime: block.timestamp + lockDurationSeconds
        });

        emit DepositReceived(msg.sender, amount, block.timestamp + lockDurationSeconds);
    }

    function withdraw() external {
        Deposit memory user = userDeposits[msg.sender];
        require(user.amount > 0, "Nothing to withdraw");
        require(block.timestamp >= user.unlockTime, "Tokens still locked");

        delete userDeposits[msg.sender];
        token.transfer(msg.sender, user.amount);

        emit TokensWithdrawn(msg.sender, user.amount);
    }

    // View function to check deposit info
    function getDepositInfo(address user) external view returns (uint256 amount, uint256 unlockTime) {
        Deposit memory d = userDeposits[user];
        return (d.amount, d.unlockTime);
    }
}
