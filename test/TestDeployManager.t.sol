// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test, console} from "forge-std/Test.sol";
import {DeployManager} from "../src/DeployManager/DeployManager.sol";
import {IDeployManager} from "../src/DeployManager/IDeployManager.sol";
import {ERC20Airdroper} from "../src/ERC20Airdroper/ERC20Airdroper.sol";
import {Mock} from "../src/MocksForTest/TestMockContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenMock} from "../src/MocksForTest/TestMockERC20.sol";

contract TestDeployManager is Test {
    ERC20Airdroper airdroper;
    DeployManager depManager;
    Mock mockContract;
    TokenMock mockToken;

    uint256 fee = 5;

    address public deployer = address(777);
    address public somebody1 = address(1);

    function setUp() public {
        vm.prank(deployer);
        depManager = new DeployManager();
        airdroper = new ERC20Airdroper();
        mockContract = new Mock();
        mockToken = new TokenMock(deployer, deployer);
    }

    function test_AddNewConctractFunctionalityEmitRevertsCheck() public {
        vm.startPrank(deployer);

        vm.expectEmit(true, false, false, true);
        emit IDeployManager.NewContractAdded(address(airdroper), 5, true, block.timestamp);
        depManager.addNewContract(address(airdroper), fee, true);

        vm.expectRevert(IDeployManager.ContractAlreadyRegistered.selector);
        depManager.addNewContract(address(airdroper), fee, false);

        vm.expectRevert();
        depManager.addNewContract(address(mockContract), fee, false);
    }

    function test_ContractActivateDeactivateFunctionalityAndEventCheck() public {
        vm.startPrank(deployer);

        vm.expectRevert(IDeployManager.ContractDoesNotRegistered.selector);
        depManager.deactivateContract(address(airdroper));

        depManager.addNewContract(address(airdroper), fee, true);
        IDeployManager.ContractInfo memory info = depManager.getContractInfo(address(airdroper));
        assertTrue(info.isActive);

        vm.expectEmit(true, false, false, true);
        emit IDeployManager.ContractStatusUpdated(address(airdroper), false, block.timestamp);
        depManager.deactivateContract(address(airdroper));
        IDeployManager.ContractInfo memory infoAfter = depManager.getContractInfo(address(airdroper));
        assertFalse(infoAfter.isActive);

        vm.expectEmit(true, false, false, true);
        emit IDeployManager.ContractStatusUpdated(address(airdroper), true, block.timestamp);
        depManager.activateContract(address(airdroper));
        IDeployManager.ContractInfo memory infoAfterActivate = depManager.getContractInfo(address(airdroper));
        assertTrue(infoAfterActivate.isActive);
    }

    function test_UpdateFeeFunctionalityCheck() public {
        vm.startPrank(deployer);

        vm.expectRevert(IDeployManager.ContractDoesNotRegistered.selector);
        depManager.updateFee(address(airdroper), 9);

        depManager.addNewContract(address(airdroper), 5, true);

        vm.expectEmit(true, false, false, true);
        emit IDeployManager.ContractFeeUpdated(address(airdroper), 5, 99, block.timestamp);
        depManager.updateFee(address(airdroper), 99);
    }

    function test_DeployRevertsCheck() public {
        vm.startPrank(deployer);
        bytes memory initRandom = bytes("Random");

        vm.expectRevert(IDeployManager.ContractDoesNotRegistered.selector);
        depManager.deploy(address(airdroper), initRandom);

        depManager.addNewContract(address(airdroper), 5, false);
        vm.expectRevert(IDeployManager.ContractDoesNotActive.selector);
        depManager.deploy(address(airdroper), initRandom);

        depManager.activateContract(address(airdroper));
        vm.expectRevert(IDeployManager.NotEnoughFunds.selector);
        depManager.deploy(address(airdroper), initRandom);

        vm.deal(deployer, fee);
        vm.expectRevert();
        depManager.deploy{value: fee}(address(airdroper), initRandom);
    }

    function test_DeployFunctionalityAndEventCheck() public {
        vm.startPrank(deployer);
        depManager.addNewContract(address(airdroper), 5, true);
        vm.stopPrank();

        bytes memory initData =
            airdroper.getInitData(address(depManager), address(mockToken), 777, address(deployer), address(somebody1));

        vm.deal(somebody1, fee);
        vm.startPrank(somebody1);
        vm.expectEmit(true, false, false, true);
        emit IDeployManager.NewDeployment(somebody1, address(0), 5, block.timestamp);
        address deployedAddr = depManager.deploy{value: fee}(address(airdroper), initData);
        assertTrue(deployedAddr != address(0));
        assertTrue(deployer.balance == 5);
    }
}
