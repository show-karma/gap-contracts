module.exports = async ({getNamedAccounts, deployments, upgrades, network}) => {
  const addresses = {
    sepolia: {
      communityResolver: "0x9FbBf6776C6d6B43C2fC17db4a05A219cC163BD8",
      easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
    }
  }
  const {log} = deployments;
  const MilestoneStatusResolver = await ethers.getContractFactory("MilestoneStatusResolver");

  const contract = await upgrades.deployProxy(MilestoneStatusResolver, [addresses[network.name].communityResolver],
     {constructorArgs: [addresses[network.name].easContract],unsafeAllow: ['constructor', 'state-variable-immutable']});
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
