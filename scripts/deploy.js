const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment of Decentralized Identity Management Contract...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // Check deployer balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");
  
  if (balance < ethers.parseEther("0.01")) {
    console.warn("Warning: Low balance. Make sure you have enough ETH for deployment.");
  }
  
  try {
    // Get the contract factory
    const DecentralizedIdentityManagement = await ethers.getContractFactory("DecentralizedIdentityManagement");
    
    console.log("Deploying DecentralizedIdentityManagement contract...");
    
    // Deploy the contract
    const contract = await DecentralizedIdentityManagement.deploy();
    
    // Wait for deployment confirmation
    await contract.waitForDeployment();
    
    const contractAddress = await contract.getAddress();
    
    console.log("✅ DecentralizedIdentityManagement contract deployed successfully!");
    console.log("📍 Contract Address:", contractAddress);
    console.log("🔗 Network:", network.name);
    console.log("⛽ Deployer Address:", deployer.address);
    
    // Get deployment transaction details
    const deploymentTx = contract.deploymentTransaction();
    console.log("📝 Deployment Transaction Hash:", deploymentTx.hash);
    console.log("💰 Gas Used:", deploymentTx.gasLimit.toString());
    
    // Verify initial state
    console.log("\n🔍 Verifying initial contract state...");
    
    const contractOwner = await contract.contractOwner();
    const isDeployerAuthorized = await contract.authorizedVerifiers(deployer.address);
    
    console.log("Contract Owner:", contractOwner);
    console.log("Deployer is Authorized Verifier:", isDeployerAuthorized);
    
    // Save deployment information
    const deploymentInfo = {
      network: network.name,
      contractAddress: contractAddress,
      deployerAddress: deployer.address,
      transactionHash: deploymentTx.hash,
      blockNumber: deploymentTx.blockNumber,
      timestamp: new Date().toISOString(),
      gasUsed: deploymentTx.gasLimit.toString(),
      contractOwner: contractOwner,
    };
    
    console.log("\n📋 Deployment Summary:");
    console.log(JSON.stringify(deploymentInfo, null, 2));
    
    // Provide interaction examples
    console.log("\n🔧 Contract Interaction Examples:");
    console.log("1. Create Identity:");
    console.log(`   contract.createIdentity("John Doe", "john@example.com")`);
    console.log("\n2. Add Credential:");
    console.log(`   contract.addCredential("education", "0x123...hash")`);
    console.log("\n3. Request Verification:");
    console.log(`   contract.requestVerification("education", "0x123...hash")`);
    
    // Network-specific instructions
    if (network.name === "core_testnet2") {
      console.log("\n🌐 Core Testnet 2 Specific Information:");
      console.log("Explorer URL: https://scan.test2.btcs.network");
      console.log(`View Contract: https://scan.test2.btcs.network/address/${contractAddress}`);
      console.log("\n💡 To interact with the contract:");
      console.log("1. Add Core Testnet 2 to your wallet");
      console.log("2. Get test tokens from the faucet");
      console.log("3. Use the contract address above to interact");
    }
    
    return {
      contractAddress,
      deployerAddress: deployer.address,
      transactionHash: deploymentTx.hash
    };
    
  } catch (error) {
    console.error("❌ Deployment failed!");
    console.error("Error:", error.message);
    
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error("💡 Solution: Add more ETH to your deployer account");
    } else if (error.code === 'NETWORK_ERROR') {
      console.error("💡 Solution: Check your network connection and RPC URL");
    } else if (error.message.includes('gas')) {
      console.error("💡 Solution: Try increasing gas limit or gas price");
    }
    
    process.exit(1);
  }
}

// Handle errors and exit gracefully
main()
  .then((result) => {
    console.log("\n🎉 Deployment completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("💥 Unexpected error:", error);
    process.exit(1);
  });
