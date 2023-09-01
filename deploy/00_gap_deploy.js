const {getAddress} = require("@ethersproject/address")
const {BigNumber} = require("@ethersproject/BigNumber")

module.exports = async ({getNamedAccounts, deployments, upgrades, network}) => {
  const {log} = deployments;
  

  const Gap = await ethers.getContractFactory("Gap");

  const gap = await upgrades.deployProxy(Gap, ["0xC2679fBD37d54388Ce493F1DB75320D236e1815e"]);
  await gap.waitForDeployment();

  console.log(gap);

  const currentImplAddress = await upgrades.erc1967.getImplementationAddress(gap.target);

  log(
    `GAP deployed as Proxy at : ${gap.target}, implementation: ${currentImplAddress}`
  );

  const GAPArtifact = await deployments.getExtendedArtifact('Gap');

  const factoryAsDeployment = {
    address: gap.target,
    ...Gap,
  };
  await deployments.save('GAPArtifact', factoryAsDeployment);

}

module.exports.tags = ['GAP'];
