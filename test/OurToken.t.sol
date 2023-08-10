// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {StdCheats} from "forge-std/StdCheats.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is StdCheats, Test {
    uint256 USER1_STARTING_AMOUNT = 100 ether;

    OurToken public ourToken;
    DeployOurToken public deployOurToken;
    address public deployerAddress;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        deployOurToken = new DeployOurToken();
        ourToken = deployOurToken.run();

        deployerAddress = vm.addr(deployOurToken.deployerKey());
        vm.prank(deployerAddress);
        ourToken.transfer(user1, USER1_STARTING_AMOUNT);
    }

    function test_User1Balance() public {
        assertEq(USER1_STARTING_AMOUNT, ourToken.balanceOf(user1));
    }

    function test_InitialSupply() public {
        assertEq(ourToken.totalSupply(), deployOurToken.INITIAL_SUPPLY());
    }

    function test_UnauthorizedMinting() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function test_TransferFrom() public {
        uint256 initialAllowance = 100 ether;

        // user1 approves user2 to spend tokens on his behalf
        vm.prank(user1);
        ourToken.approve(user2, initialAllowance);
        uint256 transferAmount = 50 ether;

        vm.prank(user2);
        ourToken.transferFrom(user1, user2, transferAmount);
        assertEq(ourToken.balanceOf(user2), transferAmount);
        assertEq(ourToken.balanceOf(user1), USER1_STARTING_AMOUNT - transferAmount);
    }

     // Test Allowances
    function test_Allowance() public {
        ourToken.approve(user2, 500 ether);
        assertEq(ourToken.allowance(address(this), user2), 500 ether);
    }

    function test_IncreaseAllowance() public {
        ourToken.increaseAllowance(user2, 300 ether);
        assertEq(ourToken.allowance(address(this), user2), 300 ether);
    }

    function test_DecreaseAllowance() public {
        ourToken.approve(user2, 500 ether);
        ourToken.decreaseAllowance(user2, 300 ether);
        assertEq(ourToken.allowance(address(this), user2), 200 ether);
    }

    // Test Transfers
    function test_Transfer() public {
        uint256 initialBalance = ourToken.balanceOf(deployerAddress);
        vm.prank(deployerAddress);
        ourToken.transfer(user1, 100 ether);
        assertEq(ourToken.balanceOf(user1), 100 ether + USER1_STARTING_AMOUNT);
        assertEq(ourToken.balanceOf(deployerAddress), initialBalance - 100 ether);
    }

    // Test for ownership
    function test_Ownership() public {
        assertEq(ourToken.owner(), deployerAddress);
    }
}
