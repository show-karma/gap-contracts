const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades, network }) => {

  const { log } = deployments;
  const MilestoneStatusResolver = await ethers.getContractFactory("MilestoneStatusResolver");

  const contract = await upgrades.deployProxy(MilestoneStatusResolver, [contractAddresses[network.name].communityResolver],
    { constructorArgs: [contractAddresses[network.name].easContract], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  await contract.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `MilestoneStatus Resolver deployed as Proxy at : ${contract.target}, implementation: ${currentImplAddress}`
  );

  const MilestoneStatusResolverArtifact = await deployments.getExtendedArtifact('MilestoneStatusResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...MilestoneStatusResolver,
  };
  await deployments.save('MilestoneStatusResolverArtifact', factoryAsDeployment);

}

module.exports.tags = ['milestone-status-resolver'];
