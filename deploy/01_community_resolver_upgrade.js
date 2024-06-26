
const { contractAddresses } = require('../util/contract-addresses');

module.exports = async ({ getNamedAccounts, deployments, upgrades }) => {

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const { log } = deployments;

  const CommunityResolver = await ethers.getContractFactory("CommunityResolver");
  const currentContract = await deployments.get("CommunityResolverArtifact");

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(currentContract.address);
  log(
    `Current CommunityResolver contracts Proxy: ${currentContract.address}, implementation: ${currentImplAddress}`
  );
  
  const contract = await upgrades.upgradeProxy(currentContract.address, CommunityResolver,
    { constructorArgs: [contractAddresses[network.name].easContract], unsafeAllow: ['constructor', 'state-variable-immutable'] });
  log(`Upgrading ...`);
  await contract.waitForDeployment();
  log(`Upgraded ...`);

  const newImplAddress = await upgrades.erc1967.getImplementationAddress(contract.target);

  log(
    `CommunityResolver deployed as Proxy at : ${contract.target}, implementation: ${newImplAddress}`
  );

  const CommunityResolverArtifact = await deployments.getExtendedArtifact('CommunityResolver');

  const factoryAsDeployment = {
    address: contract.target,
    ...CommunityResolver,
  };
  await deployments.save('CommunityResolverArtifact', factoryAsDeployment);
};

module.exports.tags = ['community-resolver-upgrade'];
