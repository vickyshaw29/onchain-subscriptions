// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {IOnChainSubscriptions} from "./interfaces/IOnchainSubscriptions.sol";
import {Subscription} from "./types/Subscription.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OnChainSubscriptions is IOnChainSubscriptions {
    error InvalidSubscription();
    error NotSubscriber();
    error SubscriptionRevokedE();
    error SubscriptionNotStarted();
    error SubscriptionExpired();
    error ChargeTooEarly();
    error TransferFailed();
    error ZeroAddress();
    error ZeroAmount();
    error InvalidInterval();
    error InvalidTimeWindow();
    error SubscriptionAlreadyExists();

    // EVENTS
    event Charged(
        bytes32 indexed subscriptionId,
        address indexed merchant,
        uint256 amount,
        uint256 chargedAt
    );
    event SubscriptionRevoked(
        bytes32 indexed subscriptionId,
        address indexed subscriber
    );

    // storage
    mapping(bytes32 => Subscription) internal subscriptions;

    function getSubscriptionId(
        address subscriber,
        address merchant,
        address token,
        uint256 salt
    ) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(subscriber, merchant, token, salt));
    }

    // modifiers

    modifier validAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    modifier nonZero(uint256 value) {
        if (value == 0) {
            revert ZeroAmount();
        }
        _;
    }

    // startTime must be in the future
    // endTime must be logically after startTime

    modifier validTimeWindow(uint256 startTime, uint256 endTime) {
        if (startTime < block.timestamp) {
            revert InvalidInterval();
        }
        if (endTime != 0 && endTime <= startTime) {
            revert InvalidTimeWindow();
        }
        _;
    }

    function createSubscription(
        address merchant,
        address token,
        uint256 amount,
        uint256 interval,
        uint256 startTime,
        uint256 endTime,
        uint256 salt
    )
        external
        override
        validAddress(merchant)
        validAddress(token)
        nonZero(amount)
        nonZero(interval)
        validTimeWindow(startTime, endTime)
        returns (bytes32 subscriptionId)
    {
        subscriptionId = getSubscriptionId(msg.sender, merchant, token, salt);

        if (subscriptions[subscriptionId].subscriber != address(0)) {
            revert SubscriptionAlreadyExists();
        }

        subscriptions[subscriptionId] = Subscription({
            subscriber: msg.sender,
            merchant: merchant,
            token: token,
            amount: amount,
            interval: interval,
            startTime: startTime,
            endTime: endTime,
            lastChargedtAt: 0,
            revoked: false
        });

        return subscriptionId;
    }

    function charge(bytes32 subscriptionId) external override {
        Subscription storage sub = subscriptions[subscriptionId];

        if (sub.subscriber == address(0)) {
            revert InvalidSubscription();
        }

        if (sub.revoked) {
            revert SubscriptionRevokedE();
        }

        if (block.timestamp < sub.startTime) {
            revert SubscriptionNotStarted();
        }

        if (sub.endTime != 0 && block.timestamp > sub.endTime) {
            revert SubscriptionExpired();
        }

        if (
            sub.lastChargedtAt != 0 &&
            block.timestamp < sub.lastChargedtAt + sub.interval
        ) {
            revert ChargeTooEarly();
        }

        bool success = IERC20(sub.token).transferFrom(
            sub.subscriber,
            sub.merchant,
            sub.amount
        );

        if (!success) {
            revert TransferFailed();
        }

        sub.lastChargedtAt = block.timestamp;

        emit Charged(subscriptionId, sub.merchant, sub.amount, block.timestamp);
    }

    function revokeSubscription(bytes32 subscriptionId) external override {
        Subscription storage sub = subscriptions[subscriptionId];
        // User has no subscription to revoke
        if(sub.subscriber == address(0)){
            revert InvalidSubscription();
        }
        if(msg.sender != sub.subscriber){
            revert NotSubscriber();
        }
        if(sub.revoked){
            revert SubscriptionRevokedE();
        }
        sub.revoked = true;
        emit SubscriptionRevoked(subscriptionId, msg.sender);
    }

    function getSubscription(
        bytes32 subscriptionId
    ) external view override returns (Subscription memory) {
        return subscriptions[subscriptionId];
    }
}
