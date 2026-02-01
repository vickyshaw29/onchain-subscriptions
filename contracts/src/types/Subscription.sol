// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

struct Subscription {
    address subscriber;
    address merchant;
    address token;
    uint256 amount;
    uint256 interval;
    uint256 lastChargedtAt;
    uint256 startTime;
    uint256 endTime;
    bool revoked;
}