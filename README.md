# SmartDeployer: On-Chain Factory for Modular Utility Smart Contracts

## 🚀 Overview

**SmartDeployer is a robust, gas-efficient, and highly flexible on-chain factory designed for deploying customized utility smart contracts via minimal proxies (ERC1167 clones).** It serves as a central hub for creating instances of various pre-audited and standardized modules, significantly reducing deployment costs and enhancing ecosystem modularity. This project is built to provide a secure and scalable solution for common Web3 functionalities, ensuring production readiness through rigorous testing and adherence to best practices.

## ✨ Features

* **Gas-Efficient Deployment:** Leverages ERC1167 minimal proxies (clones) to drastically reduce gas costs for deploying new contract instances.
* **Modular Architecture:** Provides a framework for easily integrating and deploying diverse utility modules.
* **Dynamic Initialization:** Supports complex initialization logic for cloned contracts, passing specific parameters post-deployment.
* **Adjustable Deployment Fees:** Allows the contract owner to set and update fees for each registered utility contract template.
* **Contract Lifecycle Management:** Enables the owner to activate or deactivate specific contract templates, controlling their deployability.
* **Ownership-Based Access Control:** Securely manages critical factory functions through `Ownable` from OpenZeppelin.
* **Standards Compliant:** Built using battle-tested OpenZeppelin contracts and adheres to relevant ERC standards (e.g., ERC-165).
* **Comprehensive Testing:** Rigorously tested with a comprehensive Foundry test suite to ensure reliability and correctness.

## 📦 Supported Utility Modules

SmartDeployer is designed to be extensible, currently supporting the deployment of:

* **ERC20 Airdroppers:** Distribute ERC20 tokens to multiple recipients efficiently.
* **ERC721 Airdroppers:** Facilitate the distribution of non-fungible tokens (NFTs).
* **ERC1155 Airdroppers:** Manage the distribution of semi-fungible tokens.
* **Dynamic Vesting Contracts:** Implement flexible token vesting schedules (e.g., linear, cliff-based) for various use cases.
* **Crowdfunding Campaigns:** Deploy secure and customizable contracts for decentralized fundraising initiatives.

## 🏛️ Architecture & Design

The SmartDeployer ecosystem comprises several key components:

1.  **`DeployManager.sol` (The Factory):**
    * The core contract responsible for managing and deploying clones of utility contracts.
    * Maintains a registry of approved utility contract templates with associated fees and active status.
    * Facilitates gas-efficient deployment by utilizing the `Clones` library.
    * Collects deployment fees, transferring them to the contract owner.

2.  **`IUtilityContract.sol` (Interface):**
    * Defines the essential interface (`initialize` and `getDeployManager`) that all utility contracts must implement to be compatible with `DeployManager`.
    * Ensures discoverability and proper interaction via `IERC165` interface introspection.

3.  **`AbstractUtilityContract.sol` (Base Implementation):**
    * An abstract contract that provides common functionality and state variables for all utility contracts (e.g., `deployManager` address, `initialized` status, `notInitialized` modifier).
    * Ensures that utility contracts are properly linked to their `DeployManager` instance.

4.  **Concrete Utility Contracts:**
    * Implement specific business logic (e.g., `ERC20Airdroper.sol`, `LinearVesting.sol`, `CrowdFunding.sol`).
    * Inherit from `AbstractUtilityContract` and provide their specific `initialize` function implementation to parse module-specific `_initData`.

5.  **`LibraryVesting.sol` (Reusable Logic):**
    * A utility library for complex calculations related to vesting schedules, promoting code reusability and minimizing contract size.

## 🛠️ Development Setup

To set up the project locally for development and testing:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/rozghon7/smart-deployer.git](https://github.com/rozghon7/smart-deployer.git)
    cd smart-deployer
    ```
2.  **Install Foundry:**
    If you don't have Foundry installed, follow the official guide: [Foundry Book Installation](https://book.getfoundry.sh/getting-started/installation)
    ```bash
    curl -L [https://foundry.paradigm.xyz](https://foundry.paradigm.xyz) | bash
    foundryup
    ```
3.  **Install Node.js dependencies (for `prettier` or other JS tools if used):**
    ```bash
    npm install
    ```
4.  **Install Solidity dependencies (OpenZeppelin contracts):**
    ```bash
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
    ```
    *Note: `--no-commit` prevents `forge install` from creating an extra commit.*

## 🚀 Deployment

Deployment involves two main stages:

1.  **Deploying Utility Contract Templates:**
    Each specific utility contract (e.g., `ERC20Airdroper`, `LinearVesting`, `CrowdFunding`) needs to be deployed once as a **template** (master copy). These template addresses are then registered with the `DeployManager`.

    ```bash
    # Example deployment command (replace with your actual script/method)
    forge create --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> src/UtilityContract/ERC20Airdroper.sol:ERC20Airdroper
    # Repeat for other templates: ERC721Airdroper, ERC1155Airdroper, LinearVesting, CrowdFunding
    ```

2.  **Deploying the `DeployManager`:**
    The `DeployManager` contract needs to be deployed. This will be the single entry point for users to deploy clones.

    ```bash
    forge create --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> src/DeployManager/DeployManager.sol:DeployManager
    ```

3.  **Registering Templates with `DeployManager`:**
    After `DeployManager` is deployed, the owner must register each utility contract template using `addNewContract` function, specifying the template address, a deployment fee, and initial active status.

    ```solidity
    // Example call to DeployManager (pseudo-code)
    DeployManager deployManager = DeployManager(0xYourDeployManagerAddress);
    deployManager.addNewContract(0xERC20AirdroperTemplateAddress, 1 ether, true);
    deployManager.addNewContract(0xLinearVestingTemplateAddress, 0.5 ether, true);
    deployManager.addNewContract(0xCrowdFundingTemplateAddress, 0.2 ether, true);
    // ... and so on for other modules
    ```

## 💡 Usage (Deploying a Utility Contract Instance)

Once the `DeployManager` and templates are set up, users can deploy new instances of utility contracts:

1.  **Select a registered utility contract template:**
    E.g., `0xERC20AirdroperTemplateAddress`

2.  **Prepare Initialization Data (`_initData`):**
    This is a `bytes calldata` argument that holds the specific parameters for the new instance's `initialize` function. The structure of `_initData` depends on the specific utility contract being deployed.

    * **Example for an ERC20 Airdropper:**
        The `initialize` function of `ERC20Airdroper` expects parameters like `_deployManager`, `_owner`, `_token`, `_minClaimAmount`, `_maxClaimAmount`. You would `abi.encode` these parameters.
        ```solidity
        // Pseudo-code for encoding _initData for ERC20Airdroper
        bytes memory initData = abi.encode(
            0xYourDeployManagerAddress, // deployManager
            msg.sender,                 // owner of the new airdropper
            0xSomeERC20TokenAddress,    // token to airdrop
            100,                        // minClaimAmount
            1000                        // maxClaimAmount
        );
        ```

3.  **Call `deploy` function on `DeployManager`:**
    Send the required fee along with the template address and `_initData`.

    ```solidity
    // Pseudo-code for calling deploy
    DeployManager deployManager = DeployManager(0xYourDeployManagerAddress);
    address newAirdropper = deployManager.deploy{value: FEE_FOR_AIRDROPPER}(
        0xERC20AirdroperTemplateAddress,
        initData
    );
    ```
    The `newAirdropper` address will be the address of your newly deployed, initialized utility contract.

## 🧪 Testing

The project utilizes [Foundry](https://book.getfoundry.sh/) for robust testing. To run the tests:

```bash
forge test

For verbose output:

Bash

forge test -vvvv

🔒 Security
This project prioritizes security by:

Leveraging Battle-Tested Libraries: Utilizing OpenZeppelin Contracts, which are widely audited and community-vetted.

Minimal Proxy Pattern (Clones): Reduces attack surface by deploying minimal proxies rather than full contract copies.

Clear Access Control: Implementing Ownable for critical administrative functions of the DeployManager.

Interface-Based Design: Enforcing strict interfaces (IUtilityContract, IDeployManager) for clear contract interactions.

Custom Errors: Enhancing error handling clarity and gas efficiency.

Foundry Test Suite: Comprehensive unit and integration tests help identify potential vulnerabilities.

While every effort has been made to ensure security, it's crucial for any production deployment to undergo a professional security audit.

📄 License
This project is licensed under the MIT License.

📧 Contact
For any inquiries or collaborations, feel free to reach out:

GitHub: rozghon7

Email: rozgonnni@gmail.com

LinkedIn: https://www.linkedin.com/in/mykyta-rozghon-7900a6374/
