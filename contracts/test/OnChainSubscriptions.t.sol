// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OnChainSubscriptions.sol";
import "../src/types/Subscription.sol";

contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(balanceOf[from] >= amount, "no balance");
        require(allowance[from][msg.sender] >= amount, "no allowance");

        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }
}

contract OnChainSubscriptionsTest is Test {
    OnChainSubscriptions sub;
    MockERC20 token;

    address subscriber = address(1);
    address merchant = address(2);

    function setUp() public {
        sub = new OnChainSubscriptions();
        token = new MockERC20();

        token.mint(subscriber, 1_000_000 ether);

        vm.deal(subscriber, 10 ether);

        vm.startPrank(subscriber);
        token.approve(address(sub), type(uint256).max);
        vm.stopPrank();
    }

    function testCreateAndChargeSubscription() public {
        uint256 startTime = block.timestamp + 1;
        uint256 interval = 60;
        uint256 amount = 1 ether;

        vm.startPrank(subscriber);

        bytes32 id = sub.createSubscription(
            merchant,
            address(token),
            amount,
            interval,
            startTime,
            0,
            1
        );

        vm.stopPrank();

        // fast forward time so subscription becomes active
        vm.warp(startTime + 1);

        uint256 merchantBalanceBefore = token.balanceOf(merchant);

        // anyone can call charge
        sub.charge(id);

        uint256 merchantBalanceAfter = token.balanceOf(merchant);

        assertEq(merchantBalanceAfter, merchantBalanceBefore + amount);

        // read struct correctly
        Subscription memory s = sub.getSubscription(id);

        assertEq(s.lastChargedtAt, block.timestamp);
        assertEq(s.revoked, false);
    }
}
