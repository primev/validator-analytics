import { VanillaRegistryProcessor } from "./types/eth/vanillaregistry.js";
import { EthChainId, EthFetchConfig } from "@sentio/sdk/eth";

export const TABLE_NAME = "vanilla_registry_staking";

export const STAKED_EVENT = "Staked";
export const STAKE_ADDED_EVENT = "StakeAdded";
export const UNSTAKED_EVENT = "Unstaked";
export const STAKE_WITHDRAWN_EVENT = "StakeWithdrawn";

const ethconfig: EthFetchConfig = {
  transaction: true,
  transactionReceipt: true,
  transactionReceiptLogs: true,
  block: true,
  trace: false
};

export function initVanillaRegistryProcessor(
  address: string,
  network: EthChainId
) {
    return VanillaRegistryProcessor.bind({
        address,
        network
    })
    .onEventStaked(async (event, ctx) => {
        const {
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: STAKED_EVENT,
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventStakeAdded(async (event, ctx) => {
        const {
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount,
            newBalance
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: STAKE_ADDED_EVENT,
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount,
            newBalance,
            from_address: ctx.transaction?.from,
        });
    }, undefined, ethconfig, undefined)
    .onEventUnstaked(async (event, ctx) => {
        const {
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: UNSTAKED_EVENT,
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount,
            from_address: ctx.transaction?.from,
        });
    })
    .onEventStakeWithdrawn(async (event, ctx) => {
        const {
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount
        } = event.args;
        ctx.eventLogger.emit(TABLE_NAME, {
            eventType: STAKE_WITHDRAWN_EVENT,
            msgSender,
            withdrawalAddress,
            valBLSPubKey,
            amount,
            from_address: ctx.transaction?.from,
        });
    })
}
