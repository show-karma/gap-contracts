const { contractAddresses } = require("../util/contract-addresses");

module.exports = async ({ getNamedAccounts, deployments, ethers, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const Donations = await ethers.getContractFactory("Donations");
  const platformFeePercentage = 1;

  const args = [
    contractAddresses[network.name].gapContract,
    platformFeePercentage * 100, // 1% platform fee in basis points
  ];

  const donations = await deploy("Donations", {
    from: deployer,
    args: args,
    log: true,
  });

  log(`GAP Donations deployed at : ${donations.address}`);
};

module.exports.tags = ["donations"];
