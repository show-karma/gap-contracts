module.exports = async ({getNamedAccounts, deployments, upgrades}) => {
    const addresses = {
      sepolia: {
        easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
      }
    }
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const {log} = deployments;

    const ReferrerResolver = await ethers.getContractFactory("ReferrerResolver");
    const currentContract = await deployments.get("ReferrerResolverArtifact");

    const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentContract.address);
    log(
        `Current ReferrerResolver contracts Proxy: ${currentContract.address}, implementation: ${currentImplAddress}`
    );

    const contract = await upgrades.upgradeProxy(currentContract.address, ReferrerResolver,
        {constructorArgs: [addresses[network.name].easContract],unsafeAllow: ['constructor', 'state-variable-immutable']} );
    log(`Upgrading ...`);
    await contract.waitForDeployment();
    log(`Upgraded ...`);

    const newImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

    log(
        `ReferrerResolver deployed as Proxy at : ${contract.target}, implementation: ${newImplAddress}`
    );

  const ReferrerResolverArtifact = await deployments.getExtendedArtifact('ReferrerResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...ReferrerResolver,
  };
  await deployments.save('ReferrerResolverArtifact', factoryAsDeployment);
};

module.exports.tags = ['referrer-resolver-upgrade'];