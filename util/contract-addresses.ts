import settings from "../hardhat.config";

type TContractAddresses = Record<
  keyof typeof settings.networks,
  {
    gapContract: string;
    communityResolver: string;
    easContract: string;
    projectResolver: string;
  }
>;

const contractAddresses = {
  optimism_sepolia: {
    gapContract: "0xC891F8eBA218f5034bf3a472528408BE19E1130E",
    communityResolver: "0xa5B7bbFD545A1a816aa8cBE28a1F0F2Cca58363d",
    easContract: "0x4200000000000000000000000000000000000021",
    projectResolver: "0x832931F23ea4e3c70957DA71a7eB50F5B7efA93D", // not proxy
  },
  sepolia: {
    gapContract: "0x9E5560f5b084c227Dc40672f48F59DA617eeFA28",
    communityResolver: "0xa9E55D9F52d7B47792d2Db15F6A9674c56ccc5C9",
    easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e",
    projectResolver: "0x099787D5a5aC92779A519CfD925ACB0Dc7E8bd23",
  },
  optimism: {
    gapContract: "0xd2eD366393FDfd243931Fe48e9fb65A192B0018c",
    communityResolver: "0x6dC1D6b864e8BEf815806f9e4677123496e12026",
    easContract: "0x4200000000000000000000000000000000000021",
    projectResolver: "0x7177AdC0f924b695C0294A40C4C5FEFf5EE1E141",
  },
  lisk: {
    easContract: "0x4200000000000000000000000000000000000021",
    communityResolver: "0xfddb660F2F1C27d219372210745BB9f73431856E",
    gapContract: "0x28BE0b0515be8BB8822aF1467A6613795E74717b",
    projectResolver: "0x6dC1D6b864e8BEf815806f9e4677123496e12026",
  },
  arbitrum: {
    gapContract: "0x6dC1D6b864e8BEf815806f9e4677123496e12026",
    communityResolver: "0xD534C4704F82494aBbc901560046fB62Ac63E9C4",
    easContract: "0xbD75f629A22Dc1ceD33dDA0b68c546A1c035c458",
    projectResolver: "0x28BE0b0515be8BB8822aF1467A6613795E74717b",
  },
  scroll: {
    gapContract: "0x8791Ac8c099314bB1D1514D76de13a1E80275950",
    communityResolver: "0xfddb660F2F1C27d219372210745BB9f73431856E",
    easContract: "0xC47300428b6AD2c7D03BB76D05A176058b47E6B0",
    projectResolver: "0xAFaE7aA6118D75Fe7FDB3eF8c1623cAaF8C8a653",
  },
  base_sepolia: {
    gapContract: "0x4Ca7230fB6b78875bdd1B1e4F665B7B7f1891239",
    communityResolver: "0x009dC7dF3Ea3b23CE80Fd3Ba811d5bA5675934A1",
    easContract: "0x4200000000000000000000000000000000000021",
    projectResolver: "0xC891F8eBA218f5034bf3a472528408BE19E1130E",
  },
  celo: {
    gapContract: "0x8791Ac8c099314bB1D1514D76de13a1E80275950",
    communityResolver: "0xfddb660F2F1C27d219372210745BB9f73431856E",
    easContract: "0x72E1d8ccf5299fb36fEfD8CC4394B8ef7e98Af92",
    projectResolver: "0x6dC1D6b864e8BEf815806f9e4677123496e12026",
  },
  sei_testnet: {
    gapContract: "0x0bB232f1b137fB55CB6af92c218A1cD63445a2E9",
    communityResolver: "0x50fb4a65CE924D29b9AC8C508c376a5a21Fda1BC",
    easContract: "0x4F166ed0A038ECdEEefa7Dc508f15991762974Fe",
    projectResolver: "0xdA2c62101851365EEdC5A1f7087d92Ffde7345B4",
  },
  sei: {
    gapContract: "0xB80D85690747C3E2ceCc0f8529594C6602b642D5",
    communityResolver: "0x2b79C5c2Ff877784B2FfF6d6B000801106a94a36",
    easContract: "0x391020888b0adBA584A67693458b374e4141f838",
    projectResolver: "0x96f36F25C6bD648d9bdBbd8C3E029CfB2394754d",
  }

};

export { contractAddresses };
