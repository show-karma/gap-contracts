const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const { log } = deployments;

  const MilestoneStatusResolver = await ethers.getContractFactory("ContributorProfileResolver");

  const currentContract = await deployments.get("ContributorProfileResolverArtifact");

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentContract.address);
  log(
   `Current ContributorProfileResolver contracts Proxy: ${currentContract.address}, implementation: ${currentImplAddress}`
  );

  const contract = await upgrades.upgradeProxy(currentContract.address, ContributorProfileResolver,
    { constructorArgs: [], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  log(`Upgrading ...`);
  await contract.waitForDeployment();
  log(`Upgraded ...`);

  const newImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `ContributorProfileResolver deployed as Proxy at : ${contract.target}, implementation: ${newImplAddress}`
  );

  const ContributorProfileResolverArtifact = await deployments.getExtendedArtifact('ContributorProfileResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...ContributorProfileResolver,
  };
  await deployments.save('ContributorProfileResolverArtifact', factoryAsDeployment);
};

module.exports.tags = ['contributor-profile-resolver-upgrade'];
