pub mod CONTRACT_STRUCT {
    #[derive(Drop, Serde, starknet::Store, Default, PartialEq)]
    pub struct TRANSACTION {
        // Assurez-vous que la struct est publique
        pub id: felt252,
        pub issuer: felt252,
        pub executor: felt252,
        pub amount: u128,
    }

    #[derive(Drop, Serde, starknet::Store, Default, PartialEq)]
    pub struct TRANS_STATUS {
        pub id: u8,
        pub author_type: felt252,
        pub status: felt252,
        pub action: felt252,
        pub date: ByteArray,
        pub comment: ByteArray,
    }


    #[derive(Drop, Copy, Serde, starknet::Store, Default, PartialEq)]
    pub struct PROVIDER_PAYMENT {
        pub trans_id: felt252,
        pub provider_id: felt252,
        pub amount: u128,
        pub region: felt252,
        pub to: felt252,
        pub timestamp: felt252,
    }

    #[derive(Drop, Serde, starknet::Store, Default, PartialEq, Clone)]
    pub struct PROVIDER_PAYMENT_STATUS {
        pub trans_id: felt252,
        pub action: felt252,
        pub status: felt252,
        pub comment: ByteArray,
        pub timestamp: felt252,
    }
}

pub mod CONTRACT_STRUCT_EVENT {
    #[derive(Drop, starknet::Event)]
    pub struct InitTransaction {
        pub id: felt252,
        pub issuer: felt252,
        pub executor: felt252,
        pub amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TransactionStatus {
        pub id: felt252,
        pub author_type: felt252,
        pub status: felt252,
        pub action: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct InitProviderPayment {
        pub provider_id: felt252,
        pub trans_id: felt252,
        pub amount: u128,
        pub region: felt252,
        pub to: felt252,
    }

    #[derive(Drop, starknet::Event, PartialEq)]
    pub struct ProviderPaymentStatus {
        pub action: felt252,
        pub status: felt252,
        pub comment: ByteArray,
    }
}

