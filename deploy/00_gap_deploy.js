module.exports = async ({getNamedAccounts, deployments, upgrades, network}) => {
  const addresses = {
    sepolia: {
      easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
    }
  }
  const {log} = deployments;
  const Gap = await ethers.getContractFactory("Gap");

  const gap = await upgrades.deployProxy(Gap, [addresses[network.name].easContract]);
  await gap.waitForDeployment();

  console.log(gap);

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(gap.target);

  log(
    `Gap deployed as Proxy at : ${gap.target}, implementation: ${currentImplAddress}`
  );

  const GapArtifact = await deployments.getExtendedArtifact('Gap');

  const factoryAsDeployment = {
    address: gap.target,
    ...Gap,
  };
  await deployments.save('GapArtifact', factoryAsDeployment);

}

module.exports.tags = ['gap'];
