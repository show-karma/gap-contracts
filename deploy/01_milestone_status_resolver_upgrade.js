module.exports = async ({getNamedAccounts, deployments, upgrades}) => {

    const addresses = {
      sepolia: {
        communityResolver: "0xa9E55D9F52d7B47792d2Db15F6A9674c56ccc5C9",
        easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
      }
    }
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const {log} = deployments;

    const MilestoneStatusResolver = await ethers.getContractFactory("MilestoneStatusResolver");
    const currentContract = await deployments.get("MilestoneStatusResolverArtifact");

    const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentContract.address);
    log(
        `Current MilestoneStatusResolver contracts Proxy: ${currentContract.address}, implementation: ${currentImplAddress}`
    );

    const contract = await upgrades.upgradeProxy(currentContract.address, MilestoneStatusResolver,
        {constructorArgs: [addresses[network.name].easContract], unsafeAllow: ['constructor', 'state-variable-immutable']} );
    log(`Upgrading ...`);
    await contract.waitForDeployment();
    log(`Upgraded ...`);

    const newImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

    log(
        `MilestoneStatusResolver deployed as Proxy at : ${contract.target}, implementation: ${newImplAddress}`
    );

  const MilestoneStatusResolverArtifact = await deployments.getExtendedArtifact('MilestoneStatusResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...MilestoneStatusResolver,
  };
  await deployments.save('MilestoneStatusResolverArtifact', factoryAsDeployment);
};

module.exports.tags = ['milestone-status-resolver-upgrade'];