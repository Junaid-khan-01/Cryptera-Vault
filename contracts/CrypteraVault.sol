// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CrypteraVault
 * @dev Simple ETH vault with optional time-lock per deposit and safe withdraw pattern
 * @notice Users can deposit ETH with a lock duration and withdraw after the unlock time
 */
contract CrypteraVault {
    address public owner;

    struct DepositInfo {
        uint256 amount;
        uint256 unlockTime;
        bool    exists;
    }

    // user => list of depositIds (sequential per user)
    mapping(address => uint256) public userDepositCount;
    mapping(address => mapping(uint256 => DepositInfo)) public userDeposits;

    uint256 public totalLocked;
    uint256 public totalReleased;

    event Deposited(
        address indexed user,
        uint256 indexed depositId,
        uint256 amount,
        uint256 unlockTime,
        uint256 timestamp
    );

    event Withdrawn(
        address indexed user,
        uint256 indexed depositId,
        uint256 amount,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Deposit ETH into the vault with an optional lock duration
     * @param lockDuration Seconds to lock funds (0 = no lock)
     */
    function deposit(uint256 lockDuration) external payable {
        require(msg.value > 0, "Amount = 0");

        uint256 depositId = userDepositCount[msg.sender];
        userDepositCount[msg.sender] = depositId + 1;

        uint256 unlockTime = block.timestamp + lockDuration;

        userDeposits[msg.sender][depositId] = DepositInfo({
            amount: msg.value,
            unlockTime: unlockTime,
            exists: true
        });

        totalLocked += msg.value;

        emit Deposited(
            msg.sender,
            depositId,
            msg.value,
            unlockTime,
            block.timestamp
        );
    }

    /**
     * @dev Withdraw a specific deposit after it is unlocked
     * @param depositId User-specific deposit id
     */
    function withdraw(uint256 depositId) external {
        DepositInfo storage dep = userDeposits[msg.sender][depositId];
        require(dep.exists, "No deposit");
        require(dep.amount > 0, "Already withdrawn");
        require(block.timestamp >= dep.unlockTime, "Still locked");

        uint256 amount = dep.amount;
        dep.amount = 0;          // effects first
        totalLocked -= amount;
        totalReleased += amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "Transfer failed");

        emit Withdrawn(msg.sender, depositId, amount, block.timestamp);
    }

    /**
     * @dev Get info about a user's deposit
     */
    function getDeposit(address user, uint256 depositId)
        external
        view
        returns (
            uint256 amount,
            uint256 unlockTime,
            bool exists
        )
    {
        DepositInfo memory dep = userDeposits[user][depositId];
        return (dep.amount, dep.unlockTime, dep.exists);
    }

    /**
     * @dev Get number of deposits created by a user
     */
    function getDepositCount(address user) external view returns (uint256) {
        return userDepositCount[user];
    }

    /**
     * @dev Get contract ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
