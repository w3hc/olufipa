// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/InternationalLawEnforcer.sol";
import "../src/MockKlerosCourt.sol";

/**
 * @title Deployment Script for Olufipa International Law Enforcement System
 * @author Olufipa Development Team
 * @notice Deploys the complete Olufipa system including mock Kleros court and main enforcement contract
 * @dev This script handles deployment across different networks with appropriate private key management.
 *      For local development (Anvil), it uses a hardcoded private key.
 *      For other networks, it reads the private key from environment variables.
 *
 * Usage:
 * - Local: `forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast`
 * - Testnet/Mainnet: Set PRIVATE_KEY environment variable and run with appropriate RPC URL
 *
 * @custom:security-contact security@olufipa.org
 * @custom:deployment-order 1. MockKlerosCourt 2. InternationalLawEnforcer
 */
contract Deploy is Script {
    /// @notice The default private key for local Anvil development
    /// @dev This is the first account in Anvil's default mnemonic - only use for local testing
    uint256 private constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    /// @notice Anvil's default chain ID for local development
    uint256 private constant ANVIL_CHAIN_ID = 31337;

    /**
     * @notice Emitted when contracts are successfully deployed
     * @param klerosAddress The deployed address of the MockKlerosCourt contract
     * @param enforcerAddress The deployed address of the InternationalLawEnforcer contract
     * @param deployer The address that deployed the contracts
     * @param chainId The chain ID where contracts were deployed
     */
    event ContractsDeployed(
        address indexed klerosAddress, address indexed enforcerAddress, address indexed deployer, uint256 chainId
    );

    /**
     * @notice Main deployment function that orchestrates the entire deployment process
     * @dev Determines the appropriate private key based on chain ID, then deploys both contracts
     *      in the correct order (MockKlerosCourt first, then InternationalLawEnforcer)
     */
    function run() external {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts on chain ID:", block.chainid);
        console.log("Deployer address:", deployerAddress);
        console.log("Deployer balance:", deployerAddress.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Kleros mock first since InternationalLawEnforcer depends on it
        MockKlerosCourt kleros = deployMockKleros();

        // Deploy main enforcement contract with Kleros address
        InternationalLawEnforcer intlLaw = deployInternationalLawEnforcer(address(kleros));

        vm.stopBroadcast();

        // Log deployment information
        logDeploymentInfo(address(kleros), address(intlLaw), deployerAddress);

        emit ContractsDeployed(address(kleros), address(intlLaw), deployerAddress, block.chainid);
    }

    /**
     * @notice Determines the appropriate private key for deployment
     * @dev Uses hardcoded key for local Anvil, environment variable for other networks
     * @return The private key to use for deployment
     */
    function getDeployerPrivateKey() internal view returns (uint256) {
        if (block.chainid == ANVIL_CHAIN_ID) {
            // Use default Anvil private key for local development
            return ANVIL_DEFAULT_KEY;
        } else {
            // Use private key from environment for testnets/mainnet
            return vm.envUint("PRIVATE_KEY");
        }
    }

    /**
     * @notice Deploys the MockKlerosCourt contract
     * @dev Creates a new instance of the mock arbitration system
     * @return The deployed MockKlerosCourt contract instance
     */
    function deployMockKleros() internal returns (MockKlerosCourt) {
        console.log("Deploying MockKlerosCourt...");

        MockKlerosCourt kleros = new MockKlerosCourt();

        console.log("MockKlerosCourt deployed at:", address(kleros));
        return kleros;
    }

    /**
     * @notice Deploys the InternationalLawEnforcer contract
     * @dev Creates the main enforcement contract with the provided Kleros address
     * @param klerosAddress The address of the previously deployed MockKlerosCourt
     * @return The deployed InternationalLawEnforcer contract instance
     */
    function deployInternationalLawEnforcer(address klerosAddress) internal returns (InternationalLawEnforcer) {
        console.log("Deploying InternationalLawEnforcer...");

        InternationalLawEnforcer intlLaw = new InternationalLawEnforcer(klerosAddress);

        console.log("InternationalLawEnforcer deployed at:", address(intlLaw));
        return intlLaw;
    }

    /**
     * @notice Logs comprehensive deployment information to the console
     * @dev Provides a summary of all deployed contracts and deployment details
     * @param klerosAddress Address of the deployed MockKlerosCourt
     * @param enforcerAddress Address of the deployed InternationalLawEnforcer
     * @param deployerAddress Address that deployed the contracts
     */
    function logDeploymentInfo(address klerosAddress, address enforcerAddress, address deployerAddress) internal view {
        console.log("\n==================== DEPLOYMENT COMPLETE ====================");
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Deployer:", deployerAddress);
        console.log("");
        console.log("MockKlerosCourt deployed at:", klerosAddress);
        console.log("InternationalLawEnforcer deployed at:", enforcerAddress);
        console.log("");
        console.log("Verification commands:");

        if (block.chainid != ANVIL_CHAIN_ID) {
            // Split the verification commands into multiple console.log calls
            console.log("MockKlerosCourt verification:");
            console.log("forge verify-contract");
            console.log(klerosAddress);
            console.log("src/MockKlerosCourt.sol:MockKlerosCourt");
            console.log("");

            console.log("InternationalLawEnforcer verification:");
            console.log("forge verify-contract");
            console.log(enforcerAddress);
            console.log("src/InternationalLawEnforcer.sol:InternationalLawEnforcer");
            console.log("--constructor-args");

            // Convert constructor args to hex string for verification
            bytes memory constructorArgs = abi.encode(klerosAddress);
            console.log("Constructor args (hex):");
            console.logBytes(constructorArgs);
        }

        console.log("============================================================\n");
    }

    /**
     * @notice Validates that contracts were deployed successfully
     * @dev Checks that both contracts have code at their addresses
     * @param klerosAddress Address to validate for MockKlerosCourt
     * @param enforcerAddress Address to validate for InternationalLawEnforcer
     * @return success True if both contracts have code, false otherwise
     */
    function validateDeployment(address klerosAddress, address enforcerAddress) external view returns (bool success) {
        // Check that contracts have code
        require(klerosAddress.code.length > 0, "MockKlerosCourt deployment failed");
        require(enforcerAddress.code.length > 0, "InternationalLawEnforcer deployment failed");

        return true;
    }
}
