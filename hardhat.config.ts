import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import '@typechain/hardhat'

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  typechain: {
    outDir: "@types/generated",
    target: "ethers-v5",
  },
};
export default config;
