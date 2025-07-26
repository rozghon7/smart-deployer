// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {ERC1155Airdroper} from "../src/ERC1155Airdroper/ERC1155Airdroper.sol";
import {MockToken} from "../src/MocksForTest/TestMockERC1155.sol";
import {IERC1155Airdroper} from "../src/ERC1155Airdroper/IERC1155Airdroper.sol";

contract TestERC721Airdroper is Test {
    DeployManager depManager;
    ERC1155Airdroper airdroper;
    MockToken mockToken;

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

    address deployedERC1155Contract;

    address[] receivers;
    uint256[] amounts;
    uint256[] tokenIds;

    function setUp() public {
        vm.startPrank(deployer);

        depManager = new DeployManager();
        airdroper = new ERC1155Airdroper();
        mockToken = new MockToken(deployer);

        depManager.addNewContract(address(airdroper), 5, true);
        vm.stopPrank();

        bytes memory initData =
            airdroper.getInitData(address(depManager), address(mockToken), address(deployer), address(contractOwner));

        vm.deal(contractOwner, 5);
        vm.startPrank(contractOwner);
        deployedERC1155Contract = depManager.deploy{value: 5}(address(airdroper), initData);
        assertTrue(deployedERC1155Contract != address(0));
        assertTrue(deployer.balance == 5);
    }

    function test_Airdrop721RevertsCheck() public {
        vm.startPrank(deployer);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        amounts.push(11);
        amounts.push(22);

        tokenIds.push(1);

        vm.expectRevert(IERC1155Airdroper.ArraysLengthMismatch.selector);
        airdroper.airdrop(receivers, amounts, tokenIds);

        tokenIds.push(2);
        tokenIds.push(3);

        amounts.push(33);

        vm.expectRevert();
        airdroper.airdrop(receivers, amounts, tokenIds);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);
        receivers.push(receiver4);
        receivers.push(receiver5);
        receivers.push(receiver6);
        receivers.push(receiver7);
        receivers.push(receiver8);

        amounts.push(1);
        amounts.push(2);
        amounts.push(3);
        amounts.push(4);
        amounts.push(5);
        amounts.push(6);
        amounts.push(7);
        amounts.push(8);

        tokenIds.push(4);
        tokenIds.push(5);
        tokenIds.push(6);
        tokenIds.push(7);
        tokenIds.push(8);
        tokenIds.push(9);
        tokenIds.push(10);
        tokenIds.push(11);

        vm.expectRevert(IERC1155Airdroper.IterationsQuantityMismatch.selector);
        airdroper.airdrop(receivers, amounts, tokenIds);
    }

    function test_Airdrop721FunctionalityAndEventCheck() public {
        vm.startPrank(contractOwner);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        amounts.push(1);
        amounts.push(2);
        amounts.push(3);

        tokenIds.push(1);
        tokenIds.push(2);
        tokenIds.push(3);

        ERC1155Airdroper deployedAirdroperInstance = ERC1155Airdroper(deployedERC1155Contract);
        vm.stopPrank();

        vm.startPrank(deployer);
        mockToken.mintBatch(deployer, tokenIds, amounts, "");

        mockToken.setApprovalForAll(deployedERC1155Contract, true);
        vm.stopPrank();

        vm.startPrank(contractOwner);
        vm.expectEmit(false, false, false, true);
        emit IERC1155Airdroper.AirdropSent(block.timestamp);
        deployedAirdroperInstance.airdrop(receivers, amounts, tokenIds);
    }
}
