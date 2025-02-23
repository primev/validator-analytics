import { MevCommitAVSProcessor } from "./types/eth/mevcommitavs.js";
import { EthChainId, EthFetchConfig } from "@sentio/sdk/eth";
import { SLASH_TABLE_NAME } from "./validatorSlashes.js";

export const TABLE_NAME = "mev_commit_avs";

export const OPERATOR_REGISTERED_EVENT = "OperatorRegistered";
export const OPERATOR_DEREG_REQUESTED_EVENT = "OperatorDeregistrationRequested";
export const OPERATOR_DEREG_EVENT = "OperatorDeregistered";

export const VALIDATOR_REGISTERED_EVENT = "ValidatorRegistered";
export const VALIDATOR_DEREG_REQUESTED_EVENT = "ValidatorDeregistrationRequested";
export const VALIDATOR_DEREG_EVENT = "ValidatorDeregistered";

export const FROZEN_EVENT = "ValidatorFrozen";
export const UNFROZEN_EVENT = "ValidatorUnfrozen";

const ethconfig: EthFetchConfig = {
    transaction: true,
    transactionReceipt: true,
    transactionReceiptLogs: true,
    block: true,
    trace: false
};
  
export function initMevCommitAVSProcessor(
    address: string,
    network: EthChainId
) {
    return MevCommitAVSProcessor.bind({
        address,
        network
    })
    .onEventOperatorRegistered(async (event, ctx) => {
        const {
            operator
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: OPERATOR_REGISTERED_EVENT,
            operator,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventOperatorDeregistrationRequested(async (event, ctx) => {
        const {
            operator
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: OPERATOR_DEREG_REQUESTED_EVENT,
            operator,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventOperatorDeregistered(async (event, ctx) => {
        const {
            operator
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: OPERATOR_DEREG_EVENT,
            operator,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventValidatorRegistered(async (event, ctx) => {
        const {
            validatorPubKey,
            podOwner
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: VALIDATOR_REGISTERED_EVENT,
            validatorPubKey,
            podOwner,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventValidatorDeregistrationRequested(async (event, ctx) => {
        const {
            validatorPubKey,
            podOwner
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: VALIDATOR_DEREG_REQUESTED_EVENT,
            validatorPubKey,
            podOwner,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventValidatorDeregistered(async (event, ctx) => {
        const {
            validatorPubKey,
            podOwner
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: VALIDATOR_DEREG_EVENT,
            validatorPubKey,
            podOwner,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventValidatorFrozen(async (event, ctx) => {
        const {
            validatorPubKey,
            podOwner
        } = event.args;
        ctx.eventLogger.emit(SLASH_TABLE_NAME, {
            eventType: FROZEN_EVENT,
            validatorPubKey,
            podOwner,
            from_address: ctx.transaction?.from,
        });
    })
    .onEventValidatorUnfrozen(async (event, ctx) => {
        const {
            validatorPubKey,
            podOwner
        } = event.args;
        ctx.eventLogger.emit(SLASH_TABLE_NAME, {
            eventType: UNFROZEN_EVENT,
            validatorPubKey,
            podOwner,
            from_address: ctx.transaction?.from,
        });
    })
}
