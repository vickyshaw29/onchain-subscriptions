// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import { IOnChainSubscriptions } from "./interfaces/IOnchainSubscriptions.sol";
import { Subscription } from "./types/Subscription.sol";

contract OnChainSubscriptions is IOnChainSubscriptions {
    error InvalidSubscription();
    error NotSubscriber();
    error SubscriptionRevokedE();
    error SubscriptionNotStarted();
    error SubscriptionExpired();
    error ChargeTooEarly();
    error TransferFailed();

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
    mapping(bytes32=> Subscription) internal subscriptions;

    function getSubscriptionId(
        address subscriber, address merchant, address token, uint256 salt
        ) public pure override returns(bytes32){
            return keccak256(
                abi.encodePacked(subscriber, merchant, token, salt)
            );
        }

    function createSubscription(
        address merchant, address token, uint256 amount, uint256 interval, uint256 startTime, uint256 endTime, uint256 salt
        ) external override returns(bytes32 subscriptionId){
            //
        }

    function charge(bytes32 subscriptionId) external override {

    }

    function revokeSubscription(bytes32 subscriptionId) external override {

    }

    function getSubscription(bytes32 subscriptionId) external view override returns(Subscription memory){
        return subscriptions[subscriptionId];
    }


}