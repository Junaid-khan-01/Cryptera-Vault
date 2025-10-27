// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CrypteraVault
 * @dev A decentralized vault for securely depositing and withdrawing Ether.
 * Only the owner can withdraw funds, while anyone can deposit.
 */
contract CrypteraVault {
    address public owner;
    uint256 public totalDeposits;

    mapping(address => uint256) private balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the vault
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Check user balance
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    // Withdraw Ether from the vault (only owner)
    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= address(this).balance, "Insufficient vault balance");

        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }

    // Transfer ownership of the vault
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer ownership");
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

