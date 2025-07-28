pub mod structures;
pub mod utils;
use crate::structures::CONTRACT_STRUCT::{
    PROVIDER_PAYMENT, PROVIDER_PAYMENT_STATUS, TRANSACTION, TRANS_STATUS,
};

#[starknet::interface]
pub trait CONTRACT_TRAIT<TContractState> {
    // Transaction
    fn init_transaction(ref self: TContractState, transaction: TRANSACTION);
    fn transaction_status(ref self: TContractState, trans_id: felt252, payload: TRANS_STATUS);
    fn get_transaction_status(self: @TContractState, trans_id: felt252) -> Array<TRANS_STATUS>;
    fn get_current_status(self: @TContractState, trans_id: felt252) -> TRANS_STATUS;

    // Provider
    fn init_provider_payment(
        ref self: TContractState, trans_id: felt252, payload: PROVIDER_PAYMENT,
    );
    fn provider_payment_status(
        ref self: TContractState, trans_id: felt252, payload: PROVIDER_PAYMENT_STATUS,
    );
    fn get_provider_payment_status(
        self: @TContractState, trans_id: felt252,
    ) -> Option<Array<PROVIDER_PAYMENT_STATUS>>;

    fn provider_payment_current_status(
        self: @TContractState, trans_id: felt252,
    ) -> PROVIDER_PAYMENT_STATUS;
}


#[starknet::contract]
pub mod MokaContract {
    use core::traits::Default;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec, VecTrait,
    };
    use starknet::{ContractAddress, get_caller_address};
    use crate::PROVIDER_PAYMENT;
    use crate::structures::CONTRACT_STRUCT::{PROVIDER_PAYMENT_STATUS, TRANSACTION, TRANS_STATUS};
    use crate::structures::CONTRACT_STRUCT_EVENT::{
        InitProviderPayment, InitTransaction, ProviderPaymentStatus, TransactionStatus,
    };
    use crate::utils::ERROR_MESSAGE;

    #[storage]
    struct Storage {
        name: felt252,
        description: ByteArray,
        supervisor: ContractAddress,
        transactions: Map<felt252, TRANSACTION>,
        transaction_status: Map<felt252, Vec<TRANS_STATUS>>,
        provider_payment: Map<felt252, PROVIDER_PAYMENT>,
        provider_payment_status: Map<felt252, Vec<PROVIDER_PAYMENT_STATUS>>,
    }

    // /* ------------------------------- Constructor ------------------------------ */
    #[constructor]
    fn constructor(ref self: ContractState) {
        self.name.write('Moka');
        self.description.write("Moka Contract v1.0");
        self.supervisor.write(get_caller_address());
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        InitTransaction: InitTransaction,
        TransactionStatus: TransactionStatus,
        InitProviderPayment: InitProviderPayment,
        ProviderPaymentStatus: ProviderPaymentStatus,
    }


    // /* ------------------------- Contract implementation ------------------------ */
    #[abi(embed_v0)]
    impl MokaContractImpl of super::CONTRACT_TRAIT<ContractState> {
        //a. init transaction
        fn init_transaction(ref self: ContractState, transaction: TRANSACTION) {
            //1. Verify Supervisor & check if transaction exist
            assert(self.is_supervisor(), ERROR_MESSAGE::SUPPLIER_NOT_AUTHORIZED);
            assert(
                !self.transaction_exist(transaction.id), ERROR_MESSAGE::TRANSACTION_ALREADY_EXISTS,
            );

            //2. init transaction
            let trans_id = transaction.id;
            let issuer = transaction.issuer;
            let executor = transaction.executor;
            let amount = transaction.amount;
            self.transactions.entry(trans_id).write(transaction);

            //2. init status
            let init_status = TRANS_STATUS {
                id: 1,
                author_type: 1,
                status: 1,
                action: 1,
                date: "2025-07-26",
                comment: "Transaction created",
            };
            self.add_transaction_status(trans_id, init_status);

            //4. Make event
            self.emit(InitTransaction { id: trans_id, issuer, executor, amount });
        }

        //b. update transaction status
        fn transaction_status(ref self: ContractState, trans_id: felt252, payload: TRANS_STATUS) {
            //1. Verify Supervisor && check if transaction exist
            assert(self.is_supervisor(), ERROR_MESSAGE::SUPPLIER_NOT_AUTHORIZED);
            assert(
                self.transaction_exist_on_status(trans_id),
                ERROR_MESSAGE::TRANSACTION_STATUS_NOT_FOUND,
            );

            //2. add status
            let author_type = payload.author_type;
            let status = payload.status;
            let action = payload.action;
            self.add_transaction_status(trans_id, payload);

            //4. Make event
            self.emit(TransactionStatus { id: trans_id, author_type, status, action });
        }

        //c. get transaction status
        fn get_transaction_status(self: @ContractState, trans_id: felt252) -> Array<TRANS_STATUS> {
            //1. Check if transaction exist
            assert(
                self.transaction_exist_on_status(trans_id),
                ERROR_MESSAGE::TRANSACTION_STATUS_NOT_FOUND,
            );

            //2. Get status
            let _status = self.transaction_status(trans_id);
            if (_status.is_none()) {
                return array![];
            }

            return _status.unwrap();
        }

        //d. get current status
        fn get_current_status(self: @ContractState, trans_id: felt252) -> TRANS_STATUS {
            //1. Check if transaction exist
            assert(
                self.transaction_exist_on_status(trans_id),
                ERROR_MESSAGE::TRANSACTION_STATUS_NOT_FOUND,
            );

            //2. Get status
            let index = self.transaction_status_ln(trans_id);
            let _status = self.get_status_of_index(trans_id, index);
            if (_status.is_none()) {
                return Default::default();
            }

            return _status.unwrap();
        }

        // PROVIDER

        //a. init provider payment
        fn init_provider_payment(
            ref self: ContractState, trans_id: felt252, payload: PROVIDER_PAYMENT,
        ) {
            //1. Verify Supervisor & check if transaction exist
            assert(self.is_supervisor(), ERROR_MESSAGE::SUPPLIER_NOT_AUTHORIZED);
            assert(
                !self.provider_transaction_exist(trans_id),
                ERROR_MESSAGE::TRANSACTION_ALREADY_EXISTS,
            );

            //2. init transaction
            let provider_id = payload.provider_id;
            let timestamp = payload.timestamp;
            let amount = payload.amount;
            let region = payload.region;
            let to = payload.to;

            self.provider_payment.entry(trans_id).write(payload);

            //3. init status
            let init_status = PROVIDER_PAYMENT_STATUS {
                trans_id: trans_id,
                action: 'init payment',
                status: 1,
                comment: "Payment is pending observation",
                timestamp,
            };
            self.provider_payment_status.entry(trans_id).push(init_status);

            //4. Make event
            self.emit(InitProviderPayment { trans_id, provider_id, amount, region, to });
        }

        //a. update provider payment status
        fn provider_payment_status(
            ref self: ContractState, trans_id: felt252, payload: PROVIDER_PAYMENT_STATUS,
        ) {
            // 1. Verify Supervisor & check if transaction exist
            assert(self.is_supervisor(), ERROR_MESSAGE::SUPPLIER_NOT_AUTHORIZED);
            assert(self.provider_transaction_exist(trans_id), ERROR_MESSAGE::TRANSACTION_NOT_FOUND);

            // 2. update status
            let payload_for_storage = payload.clone();
            self.provider_payment_status.entry(trans_id).push(payload);

            // 3. Make event
            let action = payload_for_storage.action;
            let status = payload_for_storage.status;
            let comment = payload_for_storage.comment;
            self.emit(ProviderPaymentStatus { action, status, comment });
        }

        //b. get provider payment status
        fn get_provider_payment_status(
            self: @ContractState, trans_id: felt252,
        ) -> Option<Array<PROVIDER_PAYMENT_STATUS>> {
            let _status = self.provider_payment_status.entry(trans_id);
            if (_status.len() == 0) {
                return Option::None;
            }

            let mut status = array![];
            for i in 0.._status.len() {
                status.append(_status.at(i).read());
            }

            return Option::Some(status);
        }

        //c.
        fn provider_payment_current_status(
            self: @ContractState, trans_id: felt252,
        ) -> PROVIDER_PAYMENT_STATUS {
            let _status = self.provider_payment_status.entry(trans_id);
            assert(_status.len() > 0, ERROR_MESSAGE::PROVIDER_PAYMENT_STATUS_NOT_FOUND);

            return _status.at(_status.len() - 1).read();
        }
    }

    // /* ------------------------- Internal functions ------------------------- */
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        //a. Check if caller is supervisor
        fn is_supervisor(self: @ContractState) -> bool {
            let address = get_caller_address();
            return self.supervisor.read() == address;
        }

        //b. Check if transaction exist
        fn transaction_exist(self: @ContractState, trans_id: felt252) -> bool {
            let transaction: TRANSACTION = self.transactions.entry(trans_id).read();
            return transaction != Default::default();
        }

        //c. Check if transaction exist on status
        fn transaction_exist_on_status(self: @ContractState, trans_id: felt252) -> bool {
            let transaction = self.transaction_status.entry(trans_id);
            return transaction.len() != 0;
        }

        //d. Get transaction
        fn get_transaction(self: @ContractState, trans_id: felt252) -> TRANSACTION {
            let transaction: TRANSACTION = self.transactions.entry(trans_id).read();
            return transaction;
        }

        //e. Get transaction status
        fn transaction_status(
            self: @ContractState, trans_id: felt252,
        ) -> Option<Array<TRANS_STATUS>> {
            let mut status = array![];

            // Check if transaction exist
            if !self.transaction_exist_on_status(trans_id) {
                return Option::None;
            }

            let _status = self.transaction_status.entry(trans_id);

            for i in 0.._status.len() {
                status.append(_status.at(i).read());
            }

            Option::Some(status)
        }

        //f. Get status of index
        fn get_status_of_index(
            self: @ContractState, trans_id: felt252, index: u64,
        ) -> Option<TRANS_STATUS> {
            let transaction_vec_accessor = self.transaction_status.entry(trans_id);
            let len = transaction_vec_accessor.len();

            if (len == 0 || index >= len) {
                return Option::None;
            }

            if let Option::Some(status_ptr) = transaction_vec_accessor.get(index) {
                return Option::Some(status_ptr.read());
            }

            return Option::None;
        }

        //g. Add transaction status
        fn add_transaction_status(
            ref self: ContractState, trans_id: felt252, status: TRANS_STATUS,
        ) {
            let transaction_vec_accessor = self.transaction_status.entry(trans_id);
            transaction_vec_accessor.push(status);
        }

        //g. Add transaction status
        fn transaction_status_ln(self: @ContractState, trans_id: felt252) -> u64 {
            if !self.transaction_exist_on_status(trans_id) {
                return 0;
            }

            let transaction_vec_accessor = self.transaction_status.entry(trans_id);
            return transaction_vec_accessor.len();
        }


        // Provider
        //a. Check if transaction exist
        fn provider_transaction_exist(self: @ContractState, trans_id: felt252) -> bool {
            let transaction: PROVIDER_PAYMENT = self.provider_payment.entry(trans_id).read();

            return transaction != Default::default();
        }

        //b. Get Provider transaction
        fn get_provider_transaction(self: @ContractState, trans_id: felt252) -> PROVIDER_PAYMENT {
            let transaction: PROVIDER_PAYMENT = self.provider_payment.entry(trans_id).read();
            return transaction;
        }

        //c. Get Provider transaction status
        fn provider_transaction_status_ln(self: @ContractState, trans_id: felt252) -> u64 {
            if !self.provider_transaction_exist(trans_id) {
                return 0;
            }

            let transaction_vec_accessor = self.provider_payment_status.entry(trans_id);
            return transaction_vec_accessor.len();
        }

        //d. Get Provider transaction status
        fn provider_transaction_status(
            self: @ContractState, trans_id: felt252,
        ) -> Option<Array<PROVIDER_PAYMENT_STATUS>> {
            let mut status = array![];

            // Check if transaction exist
            if !self.provider_transaction_exist(trans_id) {
                return Option::None;
            }

            let _status = self.provider_payment_status.entry(trans_id);

            for i in 0.._status.len() {
                status.append(_status.at(i).read());
            }

            Option::Some(status)
        }

        //e. Get Provider transaction status of index
        fn provider_transaction_status_of_index(
            self: @ContractState, trans_id: felt252, index: u64,
        ) -> Option<PROVIDER_PAYMENT_STATUS> {
            let transaction_vec_accessor = self.provider_payment_status.entry(trans_id);
            let len = transaction_vec_accessor.len();

            if (len == 0 || index >= len) {
                return Option::None;
            }

            if let Option::Some(status_ptr) = transaction_vec_accessor.get(index) {
                return Option::Some(status_ptr.read());
            }

            return Option::None;
        }
    }
}
