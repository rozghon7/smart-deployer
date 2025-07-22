// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {ERC20Airdroper} from "../src/ERC20Airdroper/ERC20Airdroper.sol";
import {TokenMock} from "../src/MocksForTest/TestMockERC20.sol";

contract TestERC20Airdroper is Test {
    DeployManager depManager;
    ERC20Airdroper airdroper;
    TokenMock mockToken;

    address deployer = makeAddr("777");

    address contractOwner = makeAddr("999");

    address receiver1 = makeAddr("1");
    address receiver2 = makeAddr("2");
    address receiver3 = makeAddr("3");
    address receiver4 = makeAddr("4");
    address receiver5 = makeAddr("5");
    address receiver6 = makeAddr("6");
    address receiver7 = makeAddr("7");
    address receiver8 = makeAddr("8");

    address deployedERC20Contract;

    address[] receivers;
    uint256[] amounts;

    function setUp() public {
        vm.startPrank(deployer);

        depManager = new DeployManager();
        airdroper = new ERC20Airdroper();
        mockToken = new TokenMock(deployer, deployer);

        depManager.addNewContract(address(airdroper), 5, true);
        vm.stopPrank();

        bytes memory initData = airdroper.getInitData(
            address(depManager), address(mockToken), 777, address(deployer), address(contractOwner)
        );

        vm.deal(contractOwner, 5);
        vm.startPrank(contractOwner);
        deployedERC20Contract = depManager.deploy{value: 5}(address(airdroper), initData);
        assertTrue(deployedERC20Contract != address(0));
        assertTrue(deployer.balance == 5);
    }

    function test_Airdrop20RevertsCheck() public {
        vm.startPrank(deployer);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        amounts.push(17);

        vm.expectRevert(ERC20Airdroper.ArraysLengthMismatch.selector);
        airdroper.airdrop(receivers, amounts);

        amounts.push(17);
        amounts.push(17);
        vm.expectRevert();
        airdroper.airdrop(receivers, amounts);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);
        receivers.push(receiver4);
        receivers.push(receiver5);
        receivers.push(receiver6);
        receivers.push(receiver7);
        receivers.push(receiver8);

        amounts.push(17);
        amounts.push(17);
        amounts.push(17);
        amounts.push(17);
        amounts.push(17);
        amounts.push(17);
        amounts.push(17);
        amounts.push(17);

        vm.expectRevert(ERC20Airdroper.IterationsQuantityMismatch.selector);
        airdroper.airdrop(receivers, amounts);
    }

    function test_Airdrop20FunctionalityAndEventCheck() public {
        vm.startPrank(contractOwner);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        amounts.push(17);
        amounts.push(17);
        amounts.push(17);

        ERC20Airdroper deployedAirdroperInstance = ERC20Airdroper(deployedERC20Contract);
        vm.stopPrank();

        vm.startPrank(deployer);
        mockToken.approve(deployedERC20Contract, 777);
        vm.stopPrank();

        vm.startPrank(contractOwner);
        vm.expectEmit(false, false, false, true);
        emit ERC20Airdroper.AirdropSent(block.timestamp);
        deployedAirdroperInstance.airdrop(receivers, amounts);
    }
}
