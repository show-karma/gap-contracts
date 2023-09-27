const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades, network }) => {
  const { log } = deployments;
  const ProjectResolver = await ethers.getContractFactory("ProjectResolver");

  const contract = await upgrades.deployProxy(ProjectResolver, [],
    { constructorArgs: [contractAddresses[network.name].easContract], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  await contract.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `ProjectResolver Resolver deployed as Proxy at : ${contract.target}, implementation: ${currentImplAddress}`
  );

  const ProjectResolverArtifact = await deployments.getExtendedArtifact('ProjectResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...ProjectResolver,
  };
  await deployments.save('ProjectResolverArtifact', factoryAsDeployment);

}

module.exports.tags = ['project-resolver'];
