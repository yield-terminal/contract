/// Module: Portfolio
module terminal::portfolio;

use std::ascii::String;
use sui::balance::{Self, Balance};
use sui::event;
use sui::linked_table::{Self, LinkedTable};
use terminal::pocket::{Self, CoinBalance};
use terminal::utils;
use terminal::wallet::{Self, Wallet, WalletBalance};

public struct Portfolio has key, store {
    id: UID,
    wallets: LinkedTable<address, LinkedTable<String, Wallet>>,
}

public struct PortfolioBalance has copy, drop, store {
    account_name: String,
    balance: WalletBalance,
}

public struct FetchAllBalancesEvent has copy, drop, store {
    owner: address,
    balances: vector<PortfolioBalance>,
    total: u64,
}

public struct FetchBalanceEvent has copy, drop, store {
    owner: address,
    account_name: String,
    balance: CoinBalance,
}

public struct FetchPoolBalanceEvent has copy, drop, store {
    owner: address,
    account_name: String,
    balance_a: CoinBalance,
    balance_b: CoinBalance,
}

public struct FetchOwnerEvent has copy, drop, store {
    owners: vector<address>,
    total: u64,
}

public struct FetchAccountEvent has copy, drop, store {
    owner: address,
    accounts: vector<String>,
    total: u64,
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

fun borrow_or_new_wallet_mut(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
): &mut Wallet {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    add_account_if_not_exist(wallets, account_name, ctx);
    linked_table::borrow_mut(wallets, account_name)
}

fun borrow_wallet_mut(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
): &mut Wallet {
    let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
    linked_table::borrow_mut(wallets, account_name)
}

fun borrow_wallet(portfolio: &Portfolio, owner: address, account_name: String): &Wallet {
    let wallets = linked_table::borrow(&portfolio.wallets, owner);
    linked_table::borrow(wallets, account_name)
}

fun has_wallets(portfolio: &Portfolio, owner: address): bool {
    linked_table::contains(&portfolio.wallets, owner)
}

fun has_wallet(portfolio: &Portfolio, owner: address, account_name: String): bool {
    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow(&portfolio.wallets, owner);
        linked_table::contains(wallets, account_name)
    } else {
        false
    }
}

public(package) fun deposit<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    let wallet = borrow_or_new_wallet_mut(portfolio, owner, account_name, ctx);
    wallet::deposit(wallet, balance);
}

public(package) fun deposit_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    let wallet = borrow_or_new_wallet_mut(portfolio, owner, account_name, ctx);
    wallet::deposit_fee(wallet, balance);
}

public(package) fun deposit_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    let wallet = borrow_or_new_wallet_mut(portfolio, owner, account_name, ctx);
    wallet::deposit_reward(wallet, balance);
}

public(package) fun withdraw<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::withdraw<T>(wallet, amount)
    } else {
        balance::zero<T>()
    }
}

public(package) fun withdraw_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::withdraw_fee<T>(wallet, amount)
    } else {
        balance::zero<T>()
    }
}

public(package) fun withdraw_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::withdraw_reward<T>(wallet, amount)
    } else {
        balance::zero<T>()
    }
}

public(package) fun apply_fee<T>(portfolio: &mut Portfolio, owner: address, account_name: String) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::apply_fee<T>(wallet);
    }
}

public(package) fun apply_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::apply_reward<T>(wallet);
    }
}

public(package) fun claim<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::transfer<T>(wallet, owner, ctx);
    }
}

public(package) fun claim_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::transfer_fee<T>(wallet, owner, ctx);
    }
}

public(package) fun claim_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet_mut(portfolio, owner, account_name);
        wallet::transfer_reward<T>(wallet, owner, ctx);
    }
}

public(package) fun claim_all<T>(portfolio: &mut Portfolio, owner: address, ctx: &mut TxContext) {
    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
        let mut option_key = wallets.front();

        while (option_key.is_some()) {
            let account_name = *option_key.borrow();
            wallet::transfer<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
            option_key = wallets.next(account_name);
        };
    }
}

public(package) fun claim_all_fee<T>(
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
        let mut option_key = wallets.front();

        while (option_key.is_some()) {
            let account_name = *option_key.borrow();
            wallet::transfer_fee<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
            option_key = wallets.next(account_name);
        };
    }
}

public(package) fun claim_all_reward<T>(
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow_mut(&mut portfolio.wallets, owner);
        let mut option_key = wallets.front();

        while (option_key.is_some()) {
            let account_name = *option_key.borrow();
            wallet::transfer_reward<T>(linked_table::borrow_mut(wallets, account_name), owner, ctx);
            option_key = wallets.next(account_name);
        };
    }
}

public fun get_all_balances(
    portfolio: &Portfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<PortfolioBalance>, u64) {
    let mut total = 0;
    let mut balances = vector::empty<PortfolioBalance>();

    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow(&portfolio.wallets, owner);
        total = wallets.length();
        let limit_value = if (limit.is_some()) { *limit.borrow() } else { total };
        let mut option_key = &utils::linked_table_key_of(wallets, offset);

        while (option_key.is_some() && balances.length() < limit_value) {
            let account_name = *option_key.borrow();
            let wallet = linked_table::borrow(wallets, account_name);
            let balance = wallet::get_all_balances(wallet);
            balances.push_back(PortfolioBalance { account_name, balance });
            option_key = wallets.next(account_name);
        };
    };

    (balances, total)
}

public fun fetch_all_balances(
    portfolio: &Portfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
) {
    let (balances, total) = get_all_balances(portfolio, owner, limit, offset);
    event::emit(FetchAllBalancesEvent {
        owner,
        balances,
        total,
    });
}

public fun get_balance<T>(
    portfolio: &Portfolio,
    owner: address,
    account_name: String,
): CoinBalance {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet(portfolio, owner, account_name);
        wallet::get_balance<T>(wallet)
    } else {
        pocket::zero_balance<T>()
    }
}

public fun fetch_balance<T>(portfolio: &Portfolio, owner: address, account_name: String) {
    let balance = get_balance<T>(
        portfolio,
        owner,
        account_name,
    );
    event::emit(FetchBalanceEvent {
        owner,
        account_name,
        balance,
    });
}

public fun get_pool_balance<CoinTypeA, CoinTypeB>(
    portfolio: &Portfolio,
    owner: address,
    account_name: String,
): (CoinBalance, CoinBalance) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallet = borrow_wallet(portfolio, owner, account_name);
        wallet::get_pool_balance<CoinTypeA, CoinTypeB>(wallet)
    } else {
        (pocket::zero_balance<CoinTypeA>(), pocket::zero_balance<CoinTypeB>())
    }
}

public fun fetch_pool_balance<A, B>(portfolio: &Portfolio, owner: address, account_name: String) {
    let (balance_a, balance_b) = get_pool_balance<A, B>(
        portfolio,
        owner,
        account_name,
    );
    event::emit(FetchPoolBalanceEvent {
        owner,
        account_name,
        balance_a,
        balance_b,
    });
}

public fun get_accounts(
    portfolio: &Portfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<String>, u64) {
    if (has_wallets(portfolio, owner)) {
        let wallets = linked_table::borrow(&portfolio.wallets, owner);
        utils::linked_table_limit_keys(wallets, limit, offset)
    } else {
        (vector::empty<String>(), 0)
    }
}

public fun fetch_accounts(
    portfolio: &Portfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
) {
    let (accounts, total) = get_accounts(portfolio, owner, limit, offset);
    event::emit(FetchAccountEvent {
        owner,
        accounts,
        total,
    });
}

public fun get_owners(
    portfolio: &Portfolio,
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<address>, u64) {
    utils::linked_table_limit_keys(&portfolio.wallets, limit, offset)
}

public fun fetch_owners(portfolio: &mut Portfolio, limit: Option<u64>, offset: Option<u64>) {
    let (owners, total) = get_owners(portfolio, limit, offset);
    event::emit(FetchOwnerEvent {
        owners,
        total,
    });
}

public fun cleanup(portfolio: &mut Portfolio, owner: address, account_name: String) {
    if (has_wallet(portfolio, owner, account_name)) {
        let wallets = portfolio.wallets.borrow_mut(owner);
        if (wallets.borrow(account_name).is_empty()) {
            wallets.remove(account_name).destroy_empty();
        }
    };
}
