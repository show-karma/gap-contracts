module.exports = async ({ getNamedAccounts, deployments, upgrades }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const { log } = deployments;

  const Donations = await ethers.getContractFactory("Donations");
  const currentContract = await deployments.get("DonationsArtifact");

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(
    currentContract.address
  );
  log(
    `Current Gap Donations contracts Proxy: ${currentContract.address}, implementation: ${currentImplAddress}`
  );

  /*
    await upgrades.forceImport(
        "0x6dC1D6b864e8BEf815806f9e4677123496e12026", Donations, {kind: 'transparent'}
    ); 
  */
  const donations = await upgrades.upgradeProxy(
    currentContract.address,
    Donations
  );
  log(`Upgrading...`);
  await donations.waitForDeployment();
  log(`Upgraded.`);

  const newImplAddress = await upgrades.erc1967.getImplementationAddress(
    donations.target
  );

  log(
    `Donations deployed as Proxy at : ${donations.target}, implementation: ${newImplAddress}`
  );

  const DonationsArtifact = await deployments.getExtendedArtifact("Donations");

  const factoryAsDeployment = {
    address: donations.target,
    ...Donations,
  };
  await deployments.save("DonationsArtifact", factoryAsDeployment);
};

module.exports.tags = ["donations-upgrade"];
