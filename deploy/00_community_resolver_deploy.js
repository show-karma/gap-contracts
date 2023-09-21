module.exports = async ({getNamedAccounts, deployments, upgrades, network}) => {
  const addresses = {
    sepolia: {
      easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
    }
  }
  const {log} = deployments;
  const CommunityResolver = await ethers.getContractFactory("CommunityResolver");

  const contract = await upgrades.deployProxy(CommunityResolver, [],
     {constructorArgs: [addresses[network.name].easContract],unsafeAllow: ['constructor', 'state-variable-immutable']});
  await contract.waitForDeployment();

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `Community Resolver deployed as Proxy at : ${contract.target}, implementation: ${currentImplAddress}`
  );

  const CommunityResolverArtifact = await deployments.getExtendedArtifact('CommunityResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...CommunityResolver,
  };
  await deployments.save('CommunityResolverArtifact', factoryAsDeployment);

}

module.exports.tags = ['community-resolver'];
