module.exports = async ({ getNamedAccounts, deployments, ethers, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  // Use a fixed salt for deterministic CREATE2 deployment across all chains
  // This ensures the same proxy address on all EVM chains
  const SALT = ethers.id("BatchDonations.v1"); // Generate consistent salt from string

  // Deploy the upgradeable contract using UUPS proxy pattern with CREATE2
  const contract = await deploy("BatchDonations", {
    from: deployer,
    log: true,
    deterministicDeployment: SALT, // Use CREATE2 with fixed salt
    proxy: {
      proxyContract: "UUPS",
      execute: {
        init: {
          methodName: "initialize",
          args: [],
        },
      },
    },
  });

  log(`BatchDonations proxy deployed at: ${contract.address}`);
  if (contract.implementation) {
    log(`Implementation deployed at: ${contract.implementation}`);
  }
  log(`Deployment used CREATE2 salt: ${SALT}`);
  log(`This address should be identical across all EVM chains`);
};

module.exports.tags = ["batch_donations"];

