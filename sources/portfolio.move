/// Module: Portfolio
module terminal::portfolio;

use std::ascii::String;
use sui::balance::Balance;
use sui::linked_table::{Self, LinkedTable};
use terminal::utils::{Self, KeysPage};
use terminal::wallet::{Self, Wallet, WalletBalance};

public struct Portfolio has key, store {
    id: UID,
    wallets: LinkedTable<address, LinkedTable<String, Wallet>>,
}

public struct PortfolioBalance has copy, drop, store {
    account_name: String,
    balance: WalletBalance,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(Portfolio {
        id: object::new(ctx),
        wallets: linked_table::new<address, LinkedTable<String, Wallet>>(ctx),
    });
}

fun add_owner_if_not_exist(portfolio: &mut Portfolio, owner: address, ctx: &mut TxContext) {
    if (!linked_table::contains(&portfolio.wallets, owner)) {
        linked_table::push_back(
            &mut portfolio.wallets,
            owner,
            linked_table::new<String, Wallet>(ctx),
        );
    }
}

fun add_account_if_not_exist(
    own_wallets: &mut LinkedTable<String, Wallet>,
    account_name: String,
    ctx: &mut TxContext,
) {
    if (!linked_table::contains(own_wallets, account_name)) {
        linked_table::push_back(own_wallets, account_name, wallet::new(ctx));
    }
}

public(package) fun deposit<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let own_wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    add_account_if_not_exist(own_wallets, account_name, ctx);
    wallet::deposit(linked_table::borrow_mut(own_wallets, account_name), balance);
}

public(package) fun deposit_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let own_wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    add_account_if_not_exist(own_wallets, account_name, ctx);
    wallet::deposit_fee(linked_table::borrow_mut(own_wallets, account_name), balance);
}

public(package) fun deposit_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let own_wallets = linked_table::borrow_mut(&mut portfolio.wallets, ctx.sender());
    add_account_if_not_exist(own_wallets, account_name, ctx);
    wallet::deposit_reward(linked_table::borrow_mut(own_wallets, account_name), balance);
}

public(package) fun withdraw<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::withdraw<T>(linked_table::borrow_mut(wallets, account_name), amount)
}

public(package) fun withdraw_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::withdraw_fee<T>(linked_table::borrow_mut(wallets, account_name), amount)
}

public(package) fun withdraw_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::withdraw_reward<T>(linked_table::borrow_mut(wallets, account_name), amount)
}

public(package) fun apply_fee<T>(portfolio: &mut Portfolio, owner: address, account_name: String) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::apply_fee<T>(linked_table::borrow_mut(wallets, account_name));
}

public(package) fun apply_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::apply_reward<T>(linked_table::borrow_mut(wallets, account_name));
}

public(package) fun claim<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::transfer<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
}

public(package) fun claim_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::transfer_fee<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
}

public(package) fun claim_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    wallet::transfer_reward<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
}

public(package) fun claim_all<T>(portfolio: &mut Portfolio, owner: address, ctx: &mut TxContext) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    let mut option_key = wallets.front();

    while (option_key.is_some()) {
        let account_name = *option_key.borrow();
        wallet::transfer<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
        option_key = wallets.next(account_name);
    };
}

public(package) fun claim_all_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    let mut option_key = wallets.front();

    while (option_key.is_some()) {
        let account_name = *option_key.borrow();
        wallet::transfer_fee<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
        option_key = wallets.next(account_name);
    };
}

public(package) fun claim_all_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    let mut option_key = wallets.front();

    while (option_key.is_some()) {
        let account_name = *option_key.borrow();
        wallet::transfer_reward<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
        option_key = wallets.next(account_name);
    };
}

public fun get_balances(portfolio: &mut Portfolio, owner: address): vector<PortfolioBalance> {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    let mut balances = vector::empty<PortfolioBalance>();
    let mut option_key = wallets.front();

    while (option_key.is_some()) {
        let account_name = *option_key.borrow();
        let wallet = linked_table::borrow(wallets, account_name);
        let balance = wallet::get_balance(wallet);
        balances.push_back(PortfolioBalance { account_name, balance });
        option_key = wallets.next(account_name);
    };

    balances
}

public fun get_accounts(portfolio: &mut Portfolio, owner: address): vector<String> {
    if (linked_table::contains(&portfolio.wallets, owner)) {
        let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
        utils::linked_table_keys(wallets)
    } else {
        vector::empty<String>()
    }
}

public fun get_owners(portfolio: &mut Portfolio, offset: u64, limit: u64): KeysPage<address> {
    utils::linked_table_keys_page(&portfolio.wallets, offset, limit)
}

public fun cleanup(portfolio: &mut Portfolio, owner: address) {
    if (linked_table::contains(&portfolio.wallets, owner)) {
        let accounts = get_accounts(portfolio, owner);
        let own_wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);

        let mut i = 0;
        while (i < accounts.length()) {
            let own_wallet = linked_table::borrow_mut(own_wallets, accounts[i]);
            if (wallet::is_empty(own_wallet)) {
                let wallet = linked_table::remove(own_wallets, accounts[i]);
                wallet::destroy_empty(wallet);
            };
            i = i + 1;
        };

        if (linked_table::is_empty(own_wallets)) {
            let wallets = linked_table::remove(&mut portfolio.wallets, owner);
            linked_table::destroy_empty(wallets);
        };
    }
}
