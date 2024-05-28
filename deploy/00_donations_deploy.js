const { contractAddresses } = require("../util/contract-addresses");

module.exports = async ({
  getNamedAccounts,
  deployments,
  upgrades,
  network,
}) => {
  const { log } = deployments;
  const Donations = await ethers.getContractFactory("Donations");

  const donations = await upgrades.deployProxy(Donations, [
    contractAddresses[network.name].gapContract,
  ]);
  await donations.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(
    donations.target
  );

  log(
    `GAP Donations deployed as Proxy at : ${donations.target}, implementation: ${currentImplAddress}`
  );

  const DonationsArtifact = await deployments.getExtendedArtifact("Donations");

  const factoryAsDeployment = {
    address: donations.target,
    ...Donations,
  };
  await deployments.save("DonationsArtifact", factoryAsDeployment);
};

module.exports.tags = ["donations"];
