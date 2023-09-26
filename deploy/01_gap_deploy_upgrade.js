module.exports = async ({getNamedAccounts, deployments, upgrades}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const {log} = deployments;

    const Gap = await ethers.getContractFactory("Gap");
    const currentGapContract = await deployments.get("GapArtifact");

    const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentGapContract.address);
    log(
        `Current Gap contracts Proxy: ${currentGapContract.address}, implementation: ${currentImplAddress}`
    );

    const gap = await upgrades.upgradeProxy(currentGapContract.address, Gap);
    log(`Upgrading ...`);
    await gap.waitForDeployment();
    log(`Upgraded ...`);

    const newImplAddress = await upgrades.erc1967.getImplementationAddress(gap.target);

    log(
        `Gap deployed as Proxy at : ${gap.target}, implementation: ${newImplAddress}`
    );

  const GapArtifact = await deployments.getExtendedArtifact('Gap');

  const factoryAsDeployment = {
    address: gap.target,
    ...Gap,
  };
  await deployments.save('GapArtifact', factoryAsDeployment);
};

module.exports.tags = ['gap-upgrade'];
