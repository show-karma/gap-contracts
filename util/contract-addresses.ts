import settings from "../hardhat.config";

type TContractAddresses = Record<
  keyof typeof settings.networks,
  {
    communityResolver: string;
    easContract: string;
  }
>;

const contractAddresses: TContractAddresses = {
  optimism_goerli: {
    communityResolver: "0xa09369bDE7E4403a9C821AffA00E649cF85Ef09e",
    easContract: "0x4200000000000000000000000000000000000021",
  },
  sepolia: {
    communityResolver: "0xa9E55D9F52d7B47792d2Db15F6A9674c56ccc5C9",
    easContract: "0xC2679fBD37d54388Ce493F1DB75320D236e1815e",
  },
  optimism: {
    communityResolver: "0x6dC1D6b864e8BEf815806f9e4677123496e12026",
    easContract: "0x4200000000000000000000000000000000000021",
  },
};

export { contractAddresses };
