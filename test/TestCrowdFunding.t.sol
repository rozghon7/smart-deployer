//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {ICrowdFunding} from "../src/CrowdFunding/ICrowdFunding.sol";
import {Crowdfunding} from "../src/CrowdFunding/Crowdfunding.sol";

contract TestCrowdFunding is Test {
    DeployManager depManager;
    Crowdfunding crowdfunding;

    address deployer = makeAddr("777");
    address contractOwner = makeAddr("999");
    address fundraiser = makeAddr("121");

    address user1 = makeAddr("1");
    address user2 = makeAddr("2");

    address deployedCrowdfundingContract;

    function setUp() public {
        vm.startPrank(deployer);

        depManager = new DeployManager();
        crowdfunding = new Crowdfunding();

        depManager.addNewContract(address(crowdfunding), 5, true);

        bytes memory initData = crowdfunding.getInitData(address(depManager), 100 ether, fundraiser, 10000, address(contractOwner));

        vm.deal(contractOwner, 5);
        vm.startPrank(contractOwner);
        deployedCrowdfundingContract = depManager.deploy{value: 5}(address(crowdfunding), initData);
    }

    function test_ContributeRevertsCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));
        vm.deal(user1, 105 ether);
        vm.startPrank(user1);

        vm.expectRevert(ICrowdFunding.InvalidValue.selector);
        deployedCrowdfundingInstance.contribute{value : 105 ether}();

        deployedCrowdfundingInstance.contribute{value : 100 ether}();

        vm.expectRevert(ICrowdFunding.PoolHasReached.selector);
        deployedCrowdfundingInstance.contribute{value : 5 ether}();
    }

    function test_ContributeFunctionalityAndEventCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));
        vm.deal(user1, 55 ether);
        vm.startPrank(user1);

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.ContributionReceived(user1, 55 ether, block.timestamp);
        deployedCrowdfundingInstance.contribute{value : 55 ether}();

        assertEq(deployedCrowdfundingInstance.donationPool(), 55 ether);
        assertFalse(deployedCrowdfundingInstance.poolReached());
        vm.stopPrank();

        vm.deal(user2, 45 ether);
        vm.startPrank(user2);

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.ContributionReceived(user2, 45 ether, block.timestamp);
        deployedCrowdfundingInstance.contribute{value : 45 ether}();

        address vestingWalletAddress = address(deployedCrowdfundingInstance.vestingWallet());
        VestingWallet vestingInstance = VestingWallet(payable(vestingWalletAddress));

        assertEq(deployedCrowdfundingInstance.donationPool(), 100 ether);
        assertTrue(deployedCrowdfundingInstance.poolReached());
        assertTrue(deployedCrowdfundingInstance.vestingStarted());
        assertTrue(deployedCrowdfundingInstance.startTimestamp() == block.timestamp);
        assertTrue(vestingWalletAddress != address(0));
        assertTrue(vestingWalletAddress.balance == 100 ether);
        assertTrue(deployedCrowdfundingContract.balance == 0);
        assertTrue(vestingInstance.owner() == fundraiser);
    }

    function test_RefundRevertsCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));
        vm.deal(user1, 55 ether);
        vm.startPrank(user1);

        vm.expectRevert(ICrowdFunding.NothingToRefund.selector);
        deployedCrowdfundingInstance.refund(10 ether);

        deployedCrowdfundingInstance.contribute{value : 55 ether}();

        vm.expectRevert(ICrowdFunding.AmountTooHigh.selector);
        deployedCrowdfundingInstance.refund(65 ether);

        vm.stopPrank();
        vm.deal(user2, 45 ether);
        vm.startPrank(user2);

        deployedCrowdfundingInstance.contribute{value : 45 ether}();

        vm.expectRevert(ICrowdFunding.PoolHasReachedAndYouCantRefund.selector);
        deployedCrowdfundingInstance.refund(45 ether);
    }

    function test_RefundFunctionalityAndEventCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));
        vm.deal(user1, 55 ether);
        vm.startPrank(user1);

        deployedCrowdfundingInstance.contribute{value : 55 ether}();

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.RefundProcessed(user1, 25 ether, block.timestamp);
        deployedCrowdfundingInstance.refund(25 ether);

        assertTrue(user1.balance == 25 ether);
        assertTrue(deployedCrowdfundingContract.balance == 30 ether);

        vm.stopPrank();
        vm.deal(user2, 45 ether);
        vm.startPrank(user2);

        deployedCrowdfundingInstance.contribute{value : 45 ether}();

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.RefundProcessed(user2, 45 ether, block.timestamp);
        deployedCrowdfundingInstance.refund(45 ether);

        assertTrue(user2.balance == 45 ether);
        assertTrue(deployedCrowdfundingContract.balance == 30 ether);
    }

    function test_WithdrawRevertsCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));
        vm.startPrank(user1);

        vm.expectRevert(ICrowdFunding.OnlyFundraiserAllowed.selector);
        deployedCrowdfundingInstance.withdraw();

        vm.startPrank(fundraiser);

        vm.expectRevert(ICrowdFunding.VestingNotStarted.selector);
        deployedCrowdfundingInstance.withdraw();
    }

    function test_WithdrawFunctionalityAndEventCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));

        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        deployedCrowdfundingInstance.contribute{value : 100 ether}();

        assertTrue(fundraiser.balance == 0);

        vm.stopPrank();
        vm.warp(block.timestamp + 5000);
        vm.startPrank(fundraiser);

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.FundsWithdrawnFromVesting(fundraiser, block.timestamp);
        deployedCrowdfundingInstance.withdraw();

        assertTrue(fundraiser.balance > 0);
    }

    function test_ReceiveRevertCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));

        vm.startPrank(user1);
        vm.deal(user1, 150 ether);
        deployedCrowdfundingInstance.contribute{value : 100 ether}();

        (bool success, ) = payable (address(deployedCrowdfundingInstance)).call{value : user1.balance}("");
        assertFalse(success, "Sending Ether after pool reached should revert");
    }

    function test_ReceiveFunctionalityAndEventCheck() public {
        Crowdfunding deployedCrowdfundingInstance = Crowdfunding(payable(deployedCrowdfundingContract));

        vm.startPrank(user1);
        vm.deal(user1, 100 ether);

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.ContributionReceived(user1, 25 ether, block.timestamp);
        (bool success, ) = payable (address(deployedCrowdfundingInstance)).call{value : 25 ether}("");
        assertTrue(success);

        assertTrue(deployedCrowdfundingInstance.donationPool() == 25 ether);

        vm.expectEmit(true, false, false, true);
        emit ICrowdFunding.ContributionReceived(user1, 75 ether, block.timestamp);
        (bool _success, ) = payable (address(deployedCrowdfundingInstance)).call{value : 75 ether}("");
        assertTrue(_success);

        address vestingWalletAddress = address(deployedCrowdfundingInstance.vestingWallet());
        VestingWallet vestingInstance = VestingWallet(payable(vestingWalletAddress));

        assertEq(deployedCrowdfundingInstance.donationPool(), 100 ether);
        assertTrue(deployedCrowdfundingInstance.poolReached());
        assertTrue(deployedCrowdfundingInstance.vestingStarted());
        assertTrue(deployedCrowdfundingInstance.startTimestamp() == block.timestamp);
        assertTrue(vestingWalletAddress != address(0));
        assertTrue(vestingWalletAddress.balance == 100 ether);
        assertTrue(deployedCrowdfundingContract.balance == 0);
        assertTrue(vestingInstance.owner() == fundraiser);
    }
}
