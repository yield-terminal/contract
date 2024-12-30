/// Module: Wallet
module terminal::wallet;

use sui::balance::Balance;
use terminal::pocket::{Self, Pocket, CoinBalance};

public struct Wallet has store {
    main: Pocket,
    fee: Pocket,
    reward: Pocket,
}

public struct WalletBalance has copy, drop, store {
    main: vector<CoinBalance>,
    fee: vector<CoinBalance>,
    reward: vector<CoinBalance>,
}

public fun new(ctx: &mut TxContext): Wallet {
    Wallet {
        main: pocket::new(ctx),
        fee: pocket::new(ctx),
        reward: pocket::new(ctx),
    }
}

public fun deposit<T>(wallet: &mut Wallet, balance: Balance<T>) {
    wallet.main.deposit<T>(balance);
}

public fun deposit_fee<T>(wallet: &mut Wallet, balance: Balance<T>) {
    wallet.fee.deposit<T>(balance);
}

public fun deposit_reward<T>(wallet: &mut Wallet, balance: Balance<T>) {
    wallet.reward.deposit<T>(balance);
}

public fun withdraw<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    wallet.main.withdraw<T>(amount)
}

public fun withdraw_fee<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    wallet.fee.withdraw<T>(amount)
}

public fun withdraw_reward<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    wallet.reward.withdraw<T>(amount)
}

public fun apply_fee<T>(wallet: &mut Wallet) {
    if (wallet.fee.contains<T>()) {
        wallet.main.deposit<T>(wallet.fee.withdraw(option::none()));
    };
}

public fun apply_reward<T>(wallet: &mut Wallet) {
    if (wallet.reward.contains<T>()) {
        wallet.main.deposit<T>(wallet.reward.withdraw(option::none()));
    };
}

public fun transfer<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    wallet.main.transfer<T>(recipient, ctx);
}

public fun transfer_fee<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    wallet.fee.transfer<T>(recipient, ctx);
}

public fun transfer_reward<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    wallet.reward.transfer<T>(recipient, ctx);
}

public fun is_empty(wallet: &Wallet): bool {
    wallet.main.is_empty() && wallet.fee.is_empty() && wallet.reward.is_empty()
}

public fun destroy_empty(wallet: Wallet) {
    let Wallet {
        main,
        fee,
        reward,
    } = wallet;
    main.destroy_empty();
    fee.destroy_empty();
    reward.destroy_empty();
}

public fun get_all_balances(wallet: &Wallet): WalletBalance {
    WalletBalance {
        main: wallet.main.get_all_balances(),
        fee: wallet.fee.get_all_balances(),
        reward: wallet.reward.get_all_balances(),
    }
}

public fun get_balance<T>(wallet: &Wallet): CoinBalance {
    wallet.main.get_balance<T>()
}

public fun get_pool_balance<A, B>(wallet: &Wallet): (CoinBalance, CoinBalance) {
    wallet.main.get_pool_balance<A, B>()
}
