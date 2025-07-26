// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {ERC721Airdroper} from "../src/ERC721Airdroper/ERC721Airdroper.sol";
import {MockToken} from "../src/MocksForTest/TestMockERC721.sol";
import {IERC721Airdroper} from "../src/ERC721Airdroper/IERC721Airdroper.sol";

contract TestERC721Airdroper is Test {
    DeployManager depManager;
    ERC721Airdroper airdroper;
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

    address deployedERC721Contract;

    address[] receivers;
    uint256[] tokenIds;

    function setUp() public {
        vm.startPrank(deployer);

        depManager = new DeployManager();
        airdroper = new ERC721Airdroper();
        mockToken = new MockToken(deployer);

        depManager.addNewContract(address(airdroper), 5, true);
        vm.stopPrank();

        bytes memory initData =
            airdroper.getInitData(address(depManager), address(mockToken), address(deployer), address(contractOwner));

        vm.deal(contractOwner, 5);
        vm.startPrank(contractOwner);
        deployedERC721Contract = depManager.deploy{value: 5}(address(airdroper), initData);
        assertTrue(deployedERC721Contract != address(0));
        assertTrue(deployer.balance == 5);
    }

    function test_Airdrop721RevertsCheck() public {
        vm.startPrank(deployer);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        tokenIds.push(1);

        vm.expectRevert(IERC721Airdroper.ArraysLengthMismatch.selector);
        airdroper.airdrop(receivers, tokenIds);

        tokenIds.push(2);
        tokenIds.push(3);
        vm.expectRevert();
        airdroper.airdrop(receivers, tokenIds);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);
        receivers.push(receiver4);
        receivers.push(receiver5);
        receivers.push(receiver6);
        receivers.push(receiver7);
        receivers.push(receiver8);

        tokenIds.push(4);
        tokenIds.push(5);
        tokenIds.push(6);
        tokenIds.push(7);
        tokenIds.push(8);
        tokenIds.push(9);
        tokenIds.push(10);
        tokenIds.push(11);

        vm.expectRevert(IERC721Airdroper.IterationsQuantityMismatch.selector);
        airdroper.airdrop(receivers, tokenIds);
    }

    function test_Airdrop721FunctionalityAndEventCheck() public {
        vm.startPrank(contractOwner);

        receivers.push(receiver1);
        receivers.push(receiver2);
        receivers.push(receiver3);

        tokenIds.push(1);
        tokenIds.push(2);
        tokenIds.push(3);

        ERC721Airdroper deployedAirdroperInstance = ERC721Airdroper(deployedERC721Contract);
        vm.stopPrank();

        vm.startPrank(deployer);
        mockToken.safeMint(deployer, 5);

        mockToken.setApprovalForAll(deployedERC721Contract, true);
        vm.stopPrank();

        vm.startPrank(contractOwner);
        vm.expectEmit(false, false, false, true);
        emit IERC721Airdroper.AirdropSent(block.timestamp);
        deployedAirdroperInstance.airdrop(receivers, tokenIds);
    }
}
