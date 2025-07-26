pub mod CONTRACT_STRUCT {
    #[derive(Drop, Serde, starknet::Store, Default, PartialEq)]
    pub struct TRANSACTION {
        // Assurez-vous que la struct est publique
        pub id: felt252,
        pub issuer: ByteArray,
        pub executor: ByteArray,
        pub amount: u128,
        pub timestamp: felt252,
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


    #[derive(Drop, Serde, starknet::Store, Default, PartialEq)]
    pub struct PROVIDER_PAYMENT {
        pub provider_id: felt252,
        pub issuer: ByteArray,
        pub executor: ByteArray,
        pub amount: u128,
        pub timestamp: felt252,
    }

    #[derive(Drop, Serde, starknet::Store, Default, PartialEq)]
    pub struct PROVIDER_PAYMENT_STATUS {
        pub status: felt252,
        pub action: felt252,
        pub comment: ByteArray,
        pub timestamp: felt252,
        pub observation: bool,
    }
}
