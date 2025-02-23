import { MevCommitMiddlewareProcessor } from "./types/eth/mevcommitmiddleware.js"
import { EthChainId, EthFetchConfig } from "@sentio/sdk/eth"

export const TABLE_NAME = "mev_commit_middleware"

export const OPERATOR_REGISTERED_EVENT = "OperatorRegistered"
export const OPERATOR_DEREG_REQUESTED_EVENT = "OperatorDeregistrationRequested"
export const OPERATOR_DEREG_EVENT = "OperatorDeregistered"
export const OPERATOR_BLACKLISTED_EVENT = "OperatorBlacklisted"
export const OPERATOR_UNBLACKLISTED_EVENT = "OperatorUnblacklisted"

export const VAULT_REGISTERED_EVENT = "VaultRegistered"
export const VAULT_SLASH_AMOUNT_UPDATED_EVENT = "VaultSlashAmountUpdated"
export const VAULT_DEREG_REQUESTED_EVENT = "VaultDeregistrationRequested"
export const VAULT_DEREG_EVENT = "VaultDeregistered"

export const VAL_RECORD_ADDED_EVENT = "ValRecordAdded"
export const VALIDATOR_DEREG_REQUESTED_EVENT = "ValidatorDeregistrationRequested"
export const VAL_RECORD_DELETED_EVENT = "ValRecordDeleted"

const ethConfig: EthFetchConfig = {
  transaction: true,
  transactionReceipt: true,
  transactionReceiptLogs: true,
  block: true,
  trace: false
}

export function initMevCommitMiddlewareProcessor(address: string, network: EthChainId) {
  return MevCommitMiddlewareProcessor.bind({
    address,
    network
  })
  .onEventOperatorRegistered(async (event, ctx) => {
    const { operator } = event.args
    ctx.eventLogger.emit(TABLE_NAME, {
        eventType: OPERATOR_REGISTERED_EVENT,
        operator,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventOperatorDeregistrationRequested(async (event, ctx) => {
      const { operator } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: OPERATOR_DEREG_REQUESTED_EVENT,
        operator,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventOperatorDeregistered(async (event, ctx) => {
      const { operator } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: OPERATOR_DEREG_EVENT,
        operator,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventOperatorBlacklisted(async (event, ctx) => {
      const { operator } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: OPERATOR_BLACKLISTED_EVENT,
        operator,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventOperatorUnblacklisted(async (event, ctx) => {
      const { operator } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: OPERATOR_UNBLACKLISTED_EVENT,
        operator,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventVaultRegistered(async (event, ctx) => {
      const { vault, slashAmount } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAULT_REGISTERED_EVENT,
        vault,
        slashAmount,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventVaultSlashAmountUpdated(async (event, ctx) => {
      const { vault, slashAmount } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAULT_SLASH_AMOUNT_UPDATED_EVENT,
        vault,
        slashAmount,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventVaultDeregistrationRequested(async (event, ctx) => {
      const { vault } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAULT_DEREG_REQUESTED_EVENT,
        vault,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventVaultDeregistered(async (event, ctx) => {
      const { vault } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAULT_DEREG_EVENT,
        vault,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventValRecordAdded(async (event, ctx) => {
      const { blsPubkey, operator, vault, position } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAL_RECORD_ADDED_EVENT,
        blsPubkey,
        operator,
        vault,
        position,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventValidatorDeregistrationRequested(async (event, ctx) => {
      const { blsPubkey, msgSender, position } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VALIDATOR_DEREG_REQUESTED_EVENT,
        blsPubkey,
        msgSender,
        position,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)

    .onEventValRecordDeleted(async (event, ctx) => {
      const { blsPubkey, msgSender } = event.args
      ctx.eventLogger.emit(TABLE_NAME, {
        eventType: VAL_RECORD_DELETED_EVENT,
        blsPubkey,
        msgSender,
        from: ctx.transaction?.from,
      })
    }, undefined, ethConfig)
}
