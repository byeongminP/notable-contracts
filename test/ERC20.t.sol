// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/ERC20.sol";

contract ERC20Test is Test {
    address internal alice;
    address internal bob;

    ERC20 internal testToken;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");

        testToken = new ERC20("Test Token", "TTN", 18);
        vm.label(address(testToken), "Test Token");
    }

    function testMetadata() public {
        assertEq(testToken.name(), "Test Token");
        assertEq(testToken.symbol(), "TTN");
        assertEq(testToken.decimals(), 18);
    }

    function testApproval() public {
        vm.prank(alice);
        assertTrue(testToken.approve(bob, 1 ether));
        assertEq(testToken.allowance(alice, bob), 1 ether);
    }

    function testTransfer() public {
        // mint tokens
        testToken.mint(alice, 1 ether);
        assertEq(testToken.totalSupply(), 1 ether);

        // transfer 1 TTN
        vm.prank(alice);
        assertTrue(testToken.transfer(bob, 1 ether));
        assertEq(testToken.totalSupply(), 1 ether);

        assertEq(testToken.balanceOf(alice), 0);
        assertEq(testToken.balanceOf(bob), 1 ether);
    }

    function testTransferFrom() public {
        // mint tokens
        testToken.mint(alice, 1 ether);
        assertEq(testToken.totalSupply(), 1 ether);

        // approve Bob to transfer 1 TTN from Alice
        vm.prank(alice);
        assertTrue(testToken.approve(bob, 1 ether));

        // transfer 1 TTN from Alice to Bob
        vm.prank(bob);
        assertTrue(testToken.transferFrom(alice, bob, 1 ether));
        assertEq(testToken.totalSupply(), 1 ether);

        assertEq(testToken.allowance(alice, bob), 0);
        assertEq(testToken.balanceOf(alice), 0);
        assertEq(testToken.balanceOf(bob), 1 ether);
    }

    function testTransferFromInfiniteApproval() public {
        // mint tokens
        testToken.mint(alice, 1 ether);
        assertEq(testToken.totalSupply(), 1 ether);

        // approve Bob to transfer 1 TTN from Alice
        vm.prank(alice);
        assertTrue(testToken.approve(bob, type(uint256).max));

        // transfer 1 TTN from Alice to Bob
        vm.prank(bob);
        assertTrue(testToken.transferFrom(alice, bob, 1 ether));
        assertEq(testToken.totalSupply(), 1 ether);

        assertEq(testToken.balanceOf(alice), 0);
        assertEq(testToken.balanceOf(bob), 1 ether);
        assertEq(testToken.allowance(alice, bob), type(uint256).max);
    }

    function testFailTransferNotEnoughBalance() public {
        // mint 1 TTN
        testToken.mint(alice, 1 ether);
        assertEq(testToken.balanceOf(alice), 1 ether);

        // transfer 2 TTN to Bob
        vm.prank(alice);
        testToken.transfer(bob, 2 ether);
    }

    function testFailTransferFromLowApproval() public {
        // mint 2 TTN
        testToken.mint(alice, 2 ether);
        assertEq(testToken.balanceOf(alice), 2 ether);

        // approve Bob to transfer 1 TTN from Alice
        vm.prank(alice);
        assertTrue(testToken.approve(bob, 1 ether));

        // transfer 2 TTN from Alice to Bob
        vm.prank(bob);
        testToken.transferFrom(alice, bob, 2 ether);
    }

    function testFailTransferFromNotEnoughBalance() public {
        // mint 1 TTN
        testToken.mint(alice, 1 ether);
        assertEq(testToken.balanceOf(alice), 1 ether);

        // approve Bob to transfer 2 TTN from Alice
        vm.prank(alice);
        assertTrue(testToken.approve(bob, 2 ether));

        // transfer 2 TTN from Alice to Bob
        vm.prank(bob);
        testToken.transferFrom(alice, bob, 2 ether);
    }

    // Fuzz testing for ERC20 functions
    function testMetadata(
        string calldata name,
        string calldata symbol,
        uint8 decimals
    ) public {
        ERC20 mockToken = new ERC20(name, symbol, decimals);
        assertEq(mockToken.name(), name);
        assertEq(mockToken.symbol(), symbol);
        assertEq(mockToken.decimals(), decimals);
    }

    function testApproval(
        address from,
        address to,
        uint256 amount
    ) public {
        vm.assume(from != address(0) && to != address(0));
        vm.prank(from);
        assertTrue(testToken.approve(to, amount));
        assertEq(testToken.allowance(from, to), amount);
    }

    function testTransfer(
        address from,
        address to,
        uint256 amount
    ) public {
        vm.assume(from != address(0) && to != address(0));
        testToken.mint(from, amount);

        vm.prank(from);
        assertTrue(testToken.transfer(to, amount));
        assertEq(testToken.totalSupply(), amount);

        if (to == from) {
            assertEq(testToken.balanceOf(to), amount);
        } else {
            assertEq(testToken.balanceOf(from), 0);
            assertEq(testToken.balanceOf(to), amount);
        }
    }

    function testTransferFrom(
        address from,
        address to,
        uint256 approval,
        uint256 amount
    ) public {
        vm.assume(from != address(0) && to != address(0));
        amount = bound(amount, 0, approval);

        testToken.mint(from, amount);

        vm.prank(from);
        assertTrue(testToken.approve(to, approval));

        vm.prank(to);
        assertTrue(testToken.transferFrom(from, to, amount));
        assertEq(testToken.totalSupply(), amount);

        uint256 allowance = approval == type(uint256).max
            ? approval
            : approval - amount;
        assertEq(testToken.allowance(from, to), allowance);

        if (to == from) {
            assertEq(testToken.balanceOf(to), amount);
        } else {
            assertEq(testToken.balanceOf(from), 0);
            assertEq(testToken.balanceOf(to), amount);
        }
    }

    function testFailTransferNotEnoughBalance(
        address from,
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        testToken.mint(from, mintAmount);

        vm.prank(from);
        sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);
        testToken.transfer(to, sendAmount);
    }

    function testFailTransferFromLowApproval(
        address from,
        address to,
        uint256 approval,
        uint256 amount
    ) public {
        vm.assume(from != to);
        testToken.mint(from, amount);

        vm.prank(from);
        approval = bound(approval, 0, amount - 1);
        assertTrue(testToken.approve(to, approval));

        vm.prank(to);
        testToken.transferFrom(from, to, amount);
    }

    function testFailTransferFromNotEnoughBalance(
        address from,
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        vm.assume(from != to);
        testToken.mint(from, mintAmount);

        vm.prank(from);
        assertTrue(testToken.approve(to, mintAmount));

        vm.prank(to);
        sendAmount = bound(sendAmount, mintAmount + 1, type(uint256).max);
        testToken.transferFrom(from, to, sendAmount);
    }
}
