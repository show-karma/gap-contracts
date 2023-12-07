const { network } = require('hardhat');
const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({getNamedAccounts, deployments, upgrades}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
    const {log} = deployments;

    const ProjectResolver = await ethers.getContractFactory("ProjectResolver");
    const currentProjectResolverContract = await deployments.get("ProjectResolverArtifact");

    const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentProjectResolverContract.address);
    log(
        `Current ProjectResolver contracts Proxy: ${currentProjectResolverContract.address}, implementation: ${currentImplAddress}`
    );

    const projectResolver = await upgrades.upgradeProxy(currentProjectResolverContract.address, ProjectResolver,
    {
      constructorArgs: [
        contractAddresses[network.name].easContract,
      ],
      unsafeAllow:
        ['constructor', 'state-variable-immutable']
    });

    log(`Upgrading ...`);
    await projectResolver.waitForDeployment();
    log(`Upgraded ...`);

    const newImplAddress = await upgrades.erc1967.getImplementationAddress(projectResolver.target);

    log(
        `ProjectResolver deployed as Proxy at : ${projectResolver.target}, implementation: ${newImplAddress}`
    );

  const ProjectResolverArtifact = await deployments.getExtendedArtifact('ProjectResolver');

  const factoryAsDeployment = {
    address: projectResolver.target,
    ...ProjectResolver,
  };
  await deployments.save('ProjectResolverArtifact', factoryAsDeployment);
};

module.exports.tags = ['project-resolver-upgrade'];
