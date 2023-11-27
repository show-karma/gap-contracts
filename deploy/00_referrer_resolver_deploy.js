const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades, network }) => {

  const { log } = deployments;
  const ReferrerResolver = await ethers.getContractFactory("ReferrerResolver");

  const contract = await upgrades.deployProxy(ReferrerResolver, [],
    { constructorArgs: [contractAddresses[network.name].easContract, contractAddresses[network.name].projectResolver], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  await contract.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `Referrer Resolver deployed as Proxy at : ${contract.target}, implementation: ${currentImplAddress}`
  );

  const ReferrerResolverArtifact = await deployments.getExtendedArtifact('ReferrerResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...ReferrerResolver,
  };
  await deployments.save('ReferrerResolverArtifact', factoryAsDeployment);

}

module.exports.tags = ['referrer-resolver'];
