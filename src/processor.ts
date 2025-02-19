import { initVanillaRegistryProcessor } from './vanillaRegistryProcessor.js'
import { EthChainId } from '@sentio/sdk/eth'

const vanillaRegistryAddress = '0x47afdcB2B089C16CEe354811EA1Bbe0DB7c335E9'
initVanillaRegistryProcessor(
  vanillaRegistryAddress, 
  EthChainId.ETHEREUM,
)

const vanillaRegistryHoleskyAddress = '0x87D5F694fAD0b6C8aaBCa96277DE09451E277Bcf'
initVanillaRegistryProcessor(
  vanillaRegistryHoleskyAddress,
  EthChainId.HOLESKY,
)
