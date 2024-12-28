/// Module: Wallet
module terminal::wallet;

use sui::balance::Balance;
use terminal::pocket::{Self, Pocket, PocketBalance};

public struct Wallet has store {
    main: Pocket,
    fee: Pocket,
    reward: Pocket,
}

public struct WalletBalance has copy, drop, store {
    main: vector<PocketBalance>,
    fee: vector<PocketBalance>,
    reward: vector<PocketBalance>,
}

public(package) fun new(ctx: &mut TxContext): Wallet {
    Wallet {
        main: pocket::new(ctx),
        fee: pocket::new(ctx),
        reward: pocket::new(ctx),
    }
}

public(package) fun deposit<T>(wallet: &mut Wallet, balance: Balance<T>) {
    pocket::deposit(&mut wallet.main, balance);
}

public(package) fun deposit_fee<T>(wallet: &mut Wallet, balance: Balance<T>) {
    pocket::deposit(&mut wallet.fee, balance);
}

public(package) fun deposit_reward<T>(wallet: &mut Wallet, balance: Balance<T>) {
    pocket::deposit(&mut wallet.reward, balance);
}

public(package) fun withdraw<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.main, amount)
}

public(package) fun withdraw_fee<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.fee, amount)
}

public(package) fun withdraw_reward<T>(wallet: &mut Wallet, amount: Option<u64>): Balance<T> {
    pocket::withdraw<T>(&mut wallet.reward, amount)
}

public(package) fun apply_fee<T>(wallet: &mut Wallet) {
    if (pocket::contains<T>(&wallet.fee)) {
        let balance = withdraw_fee<T>(wallet, option::none());
        deposit_fee<T>(wallet, balance);
    }
}

public(package) fun apply_reward<T>(wallet: &mut Wallet) {
    if (pocket::contains<T>(&wallet.reward)) {
        let balance = withdraw_reward<T>(wallet, option::none());
        deposit_reward<T>(wallet, balance);
    }
}

public(package) fun transfer<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.main, recipient, ctx);
}

public(package) fun transfer_fee<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.fee, recipient, ctx);
}

public(package) fun transfer_reward<T>(wallet: &mut Wallet, recipient: address, ctx: &mut TxContext) {
    pocket::transfer<T>(&mut wallet.reward, recipient, ctx);
}

public(package) fun is_empty(wallet: &Wallet): bool {
    pocket::is_empty(&wallet.main) && pocket::is_empty(&wallet.fee) && pocket::is_empty(&wallet.reward)
}

public(package) fun destroy_empty(wallet: Wallet) {
    let Wallet {
        main,
        fee,
        reward,
    } = wallet;
    pocket::destroy_empty(main);
    pocket::destroy_empty(fee);
    pocket::destroy_empty(reward);
}

public(package) fun get_balance(wallet: &Wallet): WalletBalance {
    WalletBalance {
        main: pocket::get_balance(&wallet.main),
        fee: pocket::get_balance(&wallet.fee),
        reward: pocket::get_balance(&wallet.reward),
    }
}
