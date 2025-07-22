// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVesting} from "../src/LiniarVesting/IVesting.sol";
import {Vesting} from "../src/LiniarVesting/Vesting.sol";
import {TokenMock} from "../src/MocksForTest/TestMockERC20.sol";

contract TestLiniarVesting is Test {
    DeployManager depManager;
    Vesting vesting;
    TokenMock mockToken;

    address deployer = makeAddr("777");
    address contractOwner = makeAddr("999");

    address deployedVestingContract;

    address beneficiary = makeAddr("121");

    function setUp() public {
        vm.startPrank(deployer);

        depManager = new DeployManager();
        vesting = new Vesting();
        mockToken = new TokenMock(deployer, deployer);

        depManager.addNewContract(address(vesting), 5, true);
        vm.stopPrank();

        bytes memory initData = vesting.getInitData(address(depManager), address(mockToken), address(contractOwner));

        vm.deal(contractOwner, 5);
        vm.startPrank(contractOwner);
        deployedVestingContract = depManager.deploy{value: 5}(address(vesting), initData);
        assertTrue(deployedVestingContract != address(0));
        assertTrue(deployer.balance == 5);
    }

    function test_StartVestingRevertsCheck() public {
        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);

        IVesting.VestingParameters memory params;

        params.beneficiary = address(0);
        params.totalAmount = 100;
        params.startTime = 10000000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(IVesting.InvalidBeneficiary.selector);
        deployedVestingInstance.startVesting(params);

        params.beneficiary = beneficiary;
        params.totalAmount = 10;
        params.startTime = 10000000;
        params.cliff = 1000;
        params.duration = 0;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(IVesting.DurationCantBeZero.selector);
        deployedVestingInstance.startVesting(params);

        params.beneficiary = beneficiary;
        params.totalAmount = 0;
        params.startTime = 10000000;
        params.cliff = 1000;
        params.duration = 100;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(IVesting.AmountCantBeZero.selector);
        deployedVestingInstance.startVesting(params);

        params.beneficiary = beneficiary;
        params.totalAmount = 1000;
        params.startTime = 0;
        params.cliff = 1000;
        params.duration = 100;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(
            abi.encodeWithSelector(IVesting.StartTimeShouldBeFuture.selector, params.startTime, block.timestamp)
        );
        deployedVestingInstance.startVesting(params);

        params.beneficiary = beneficiary;
        params.totalAmount = 1000;
        params.startTime = 1753127629;
        params.cliff = 1000;
        params.duration = 100;
        params.claimCooldown = 10000000;
        params.minClaimAmount = 10;

        vm.expectRevert(
            abi.encodeWithSelector(
                IVesting.CooldownCantBeLongerThanDuration.selector, params.claimCooldown, params.duration
            )
        );
        deployedVestingInstance.startVesting(params);

        vm.stopPrank();
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();
        vm.startPrank(contractOwner);

        params.beneficiary = beneficiary;
        params.totalAmount = 100000;
        params.startTime = 1753127629;
        params.cliff = 1000;
        params.duration = 100000;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(abi.encodeWithSelector(IVesting.InsufficientBalance.selector, 10000, 100000));
        deployedVestingInstance.startVesting(params);
    }

    function test_StartVestingFunctionalityAndEventAndRevertAlreadyExistCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);

        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = 1753127629;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectEmit(true, false, false, true);
        emit IVesting.VestingCreated(beneficiary, params.totalAmount, block.timestamp);
        deployedVestingInstance.startVesting(params);

        IVesting.VestingInfo memory actualVestingInfo;
        (
            actualVestingInfo.totalAmount,
            actualVestingInfo.startTime,
            actualVestingInfo.cliff,
            actualVestingInfo.duration,
            actualVestingInfo.claimed,
            actualVestingInfo.lastClaimTime,
            actualVestingInfo.claimCooldown,
            actualVestingInfo.minClaimAmount,
            actualVestingInfo.created
        ) = deployedVestingInstance.vestings(beneficiary);

        assertEq(actualVestingInfo.totalAmount, params.totalAmount);
        assertEq(actualVestingInfo.startTime, params.startTime);
        assertEq(actualVestingInfo.cliff, params.cliff);
        assertEq(actualVestingInfo.duration, params.duration);
        assertEq(actualVestingInfo.claimed, 0);
        assertEq(actualVestingInfo.lastClaimTime, 0);
        assertEq(actualVestingInfo.claimCooldown, params.claimCooldown);
        assertEq(actualVestingInfo.minClaimAmount, params.minClaimAmount);
        assertEq(actualVestingInfo.created, true);

        vm.stopPrank();
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();
        vm.startPrank(contractOwner);

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = 1753127629;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        vm.expectRevert(IVesting.VestingAlreadyExists.selector);
        deployedVestingInstance.startVesting(params);
    }

    function test_VestedAmountFunctionalityCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);

        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = block.timestamp + 1000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 100;
        params.minClaimAmount = 10;

        deployedVestingInstance.startVesting(params);

        uint256 vestedAmount = deployedVestingInstance.vestedAmount(beneficiary);
        assertEq(vestedAmount, 0);

        vm.warp(block.timestamp + 5000);
        vestedAmount = deployedVestingInstance.vestedAmount(beneficiary);
        assertEq(vestedAmount, 3000);
    }

    function test_ClaimRevertsCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);

        vm.expectRevert(IVesting.VestingNotFound.selector);
        deployedVestingInstance.claim();

        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = block.timestamp + 1000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 10;
        params.minClaimAmount = 100;

        deployedVestingInstance.startVesting(params);

        vm.stopPrank();
        vm.startPrank(beneficiary);

        vm.expectRevert(
            abi.encodeWithSelector(
                IVesting.ClaimNotAvailable.selector, block.timestamp, (params.startTime + params.cliff)
            )
        );
        deployedVestingInstance.claim();

        vm.warp(block.timestamp + 5000);

        deployedVestingInstance.claim();

        vm.expectRevert(abi.encodeWithSelector(IVesting.CooldownNotPassed.selector, block.timestamp, block.timestamp));
        deployedVestingInstance.claim();

        vm.warp(block.timestamp + 85);

        uint256 claimable = deployedVestingInstance.claimableAmount(beneficiary);
        console.log(claimable);

        vm.expectRevert(abi.encodeWithSelector(IVesting.BelowMinimalClaimAmount.selector, claimable, 100));
        deployedVestingInstance.claim();
    }

    function test_ClaimFunctionalityAndEventCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);

        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = block.timestamp + 1000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 10;
        params.minClaimAmount = 100;

        deployedVestingInstance.startVesting(params);

        vm.stopPrank();
        vm.startPrank(beneficiary);

        vm.warp(block.timestamp + 9999);

        uint256 claimableNow = deployedVestingInstance.claimableAmount(beneficiary);

        vm.expectEmit(true, false, false, true);
        emit IVesting.Claim(beneficiary, claimableNow, block.timestamp);
        deployedVestingInstance.claim();
    }

    function test_withdrawUnallocatedFunctionalityEventCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);
        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = block.timestamp + 1000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 10;
        params.minClaimAmount = 100;

        deployedVestingInstance.startVesting(params);

        vm.stopPrank();
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();
        vm.startPrank(contractOwner);

        uint256 balanceBeforeWithdraw = mockToken.balanceOf(deployer);

        vm.expectEmit(true, false, false, true);
        emit IVesting.TokensWithdrawn(deployer, 10000);
        deployedVestingInstance.withdrawUnallocated(deployer);
        assertTrue(mockToken.balanceOf(deployer) == balanceBeforeWithdraw + 10000);
    }

    function test_withdrawUnallocatedRevertCheck() public {
        vm.startPrank(deployer);
        mockToken.mint(deployedVestingContract, 10000);
        vm.stopPrank();

        vm.startPrank(contractOwner);

        Vesting deployedVestingInstance = Vesting(deployedVestingContract);
        IVesting.VestingParameters memory params;

        params.beneficiary = beneficiary;
        params.totalAmount = 10000;
        params.startTime = block.timestamp + 1000;
        params.cliff = 1000;
        params.duration = 10000;
        params.claimCooldown = 10;
        params.minClaimAmount = 100;

        deployedVestingInstance.startVesting(params);

        vm.expectRevert(IVesting.NothingToWithdraw.selector);
        deployedVestingInstance.withdrawUnallocated(deployer);
    }
}
