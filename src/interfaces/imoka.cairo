use crate::structures::CONTRACT_STRUCT::{TRANSACTION, TRANS_STATUS};

#[starknet::interface]
pub trait CONTRACT_TRAIT<TContractState> {
    fn init_transaction(ref self: TContractState, transaction: TRANSACTION);
    fn transaction_status(ref self: TContractState, trans_id: felt252, status: TRANS_STATUS);
    fn get_transaction_status(self: @TContractState, trans_id: felt252) -> TRANS_STATUS;
}
