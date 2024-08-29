module.exports = async ({ getNamedAccounts, deployments, ethers, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const GitcoinAirdrop = await ethers.getContractFactory("AirdropNFT");

  const args = [
    // _name, _symbol, _platformFee
    "Karma GAP Patron",
    "Karma GAP",
    1000,
    "ipfs://QmX4BM91rsnopQBoGk7oGwdvaaDnpPokc4oyskuLRdG5Tb",
  ];

  const airdrop = await deploy("AirdropNFT", {
    from: deployer,
    args: args,
    log: true,
  });

  log(`Airdrop NFT deployed at : ${airdrop.address}`);
};

module.exports.tags = ["airdrop_nfts"];
