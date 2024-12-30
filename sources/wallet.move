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
    pocket::deposit(&mut wallet.main, balance);
}

public fun deposit_fee<T>(wallet: &mut Wallet, balance: Balance<T>) {
    pocket::deposit(&mut wallet.fee, balance);
}

public fun deposit_reward<T>(wallet: &mut Wallet, balance: Balance<T>) {
    pocket::deposit(&mut wallet.reward, balance);
}

public fun withdraw<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.main, amount)
}

public fun withdraw_fee<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.fee, amount)
}

public fun withdraw_reward<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.reward, amount)
}

public fun apply_fee<T>(wallet: &mut Wallet) {
    if (pocket::contains<T>(&wallet.fee)) {
        let balance = withdraw_fee<T>(wallet, option::none());
        deposit<T>(wallet, balance);
    }
}

public fun apply_reward<T>(wallet: &mut Wallet) {
    if (pocket::contains<T>(&wallet.reward)) {
        let balance = withdraw_reward<T>(wallet, option::none());
        deposit<T>(wallet, balance);
    }
}

public fun transfer<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.main, recipient, ctx);
}

public fun transfer_fee<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.fee, recipient, ctx);
}

public fun transfer_reward<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.reward, recipient, ctx);
}

public fun is_empty(wallet: &Wallet): bool {
    pocket::is_empty(&wallet.main) && pocket::is_empty(&wallet.fee) && pocket::is_empty(&wallet.reward)
}

public fun destroy_empty(wallet: Wallet) {
    let Wallet {
        main,
        fee,
        reward,
    } = wallet;
    pocket::destroy_empty(main);
    pocket::destroy_empty(fee);
    pocket::destroy_empty(reward);
}

public fun get_all_balances(wallet: &Wallet): WalletBalance {
    WalletBalance {
        main: pocket::get_all_balances(&wallet.main),
        fee: pocket::get_all_balances(&wallet.fee),
        reward: pocket::get_all_balances(&wallet.reward),
    }
}

public fun get_balance<T>(wallet: &Wallet): CoinBalance {
    pocket::get_balance<T>(&wallet.main)
}

public fun get_pool_balance<A, B>(wallet: &Wallet): (CoinBalance, CoinBalance) {
    pocket::get_pool_balance<A, B>(&wallet.main)
}
