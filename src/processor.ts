import { initVanillaRegistryProcessor } from './vanillaRegistryProcessor.js'
import { initMevCommitAVSProcessor } from './mevCommitAVSProcessor.js'
import { initMevCommitMiddlewareProcessor } from './mevCommitMiddlewareProcessor.js'
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

const mevCommitAVSAddress = '0xBc77233855e3274E1903771675Eb71E602D9DC2e'
initMevCommitAVSProcessor(
  mevCommitAVSAddress,
  EthChainId.ETHEREUM,
)

const mevCommitAVSHoleskyAddress = '0xEDEDB8ed37A43Fd399108A44646B85b780D85DD4'
initMevCommitAVSProcessor(
  mevCommitAVSHoleskyAddress,
  EthChainId.HOLESKY,
)

const mevCommitMiddlewareAddress = '0x21fD239311B050bbeE7F32850d99ADc224761382'
initMevCommitMiddlewareProcessor(
  mevCommitMiddlewareAddress,
  EthChainId.ETHEREUM,
)

const mevCommitMiddlewareHoleskyAddress = '0x79FeCD427e5A3e5f1a40895A0AC20A6a50C95393'
initMevCommitMiddlewareProcessor(
  mevCommitMiddlewareHoleskyAddress,
  EthChainId.HOLESKY,
)
