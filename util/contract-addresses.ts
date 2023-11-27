import settings from '../hardhat.config';

type TContractAddresses = Record<
  keyof typeof settings.networks,
  {
    communityResolver: string;
    easContract: string;
    projectResolver: string;
  }
>;

const contractAddresses: TContractAddresses = {
  optimism_goerli: {
    communityResolver: '0xa09369bDE7E4403a9C821AffA00E649cF85Ef09e',
    easContract: '0x4200000000000000000000000000000000000021',
    projectResolver: '0x0d63f7820d97C12139d60791BC9996f6Fe2b9C85',// not proxy
  },
  sepolia: {
    communityResolver: '0xa9E55D9F52d7B47792d2Db15F6A9674c56ccc5C9',
    easContract: '0xC2679fBD37d54388Ce493F1DB75320D236e1815e',
    projectResolver: '',
  },
  optimism: {
    communityResolver: '0x6dC1D6b864e8BEf815806f9e4677123496e12026',
    easContract: '0x4200000000000000000000000000000000000021',
    projectResolver: '0x7177AdC0f924b695C0294A40C4C5FEFf5EE1E141',
  },
};

export { contractAddresses };
