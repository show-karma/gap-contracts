const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades, network }) => {
  const { log } = deployments;
  const ContributorProfileResolver = await ethers.getContractFactory("ContributorProfileResolver");

  const contract = await upgrades.deployProxy(ContributorProfileResolver, [],
    { constructorArgs: [contractAddresses[network.name].easContract], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  await contract.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `ContributorProfile Resolver deployed as Proxy at : ${contract.target}, implementation: ${currentImplAddress}`
  );

  const ContributorProfileResolverArtifact = await deployments.getExtendedArtifact('ContributorProfileResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...ContributorProfileResolver,
  };
  await deployments.save('ContributorProfileResolverArtifact', factoryAsDeployment);

}

module.exports.tags = ['contributor-profile-resolver'];
