module.exports = async ({ getNamedAccounts, deployments, ethers, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const GitcoinAirdrop = await ethers.getContractFactory("GitcoinAirdrop");

  const args = [
    // _name, _symbol, _platformFee
    "Gitcoin Contributors Airdrop",
    "GCA",
    1000,
  ];

  const airdrop = await deploy("GitcoinAirdrop", {
    from: deployer,
    args: args,
    log: true,
  });

  log(`Gitcoin Airdrop deployed at : ${airdrop.address}`);
};

module.exports.tags = ["gitcoin_airdrop"];
