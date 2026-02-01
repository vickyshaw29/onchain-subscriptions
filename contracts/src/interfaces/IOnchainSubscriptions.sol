// SPDX-License-Identier:MIT

pragma solidity ^0.8.20;
import { Subscription } from "../types/Subscription.sol";

interface IOnChainSubscriptions {
    function getSubscriptionId(
        address subscriber,
        address merchant,
        address token,
        uint256 salt
    ) external pure returns (bytes32);

    function createSubscription(
        address merchant,
        address token,
        uint256 amount,
        uint256 interval,
        uint256 startTime,
        uint256 endTime,
        uint256 salt
    )external returns(bytes32 subscriptionId);

    function charge(bytes32 subscriptionId) external;

    function revokeSubscription(bytes32 subscriptionId) external;

    function getSubscription(bytes32 subscriptionId) external view returns(Subscription memory);
}