/// Module: Admin Portfolio
module terminal::admin_portfolio;

use std::ascii::String;
use sui::balance::Balance;
use terminal::config::AdminCap;
use terminal::portfolio::{Self, Portfolio};

public fun deposit<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit<T>(portfolio, owner, account_name, balance, ctx);
}

public fun deposit_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit_fee<T>(portfolio, owner, account_name, balance, ctx);
}

public fun deposit_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    balance: Balance<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit_reward<T>(portfolio, owner, account_name, balance, ctx);
}

public fun withdraw<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    portfolio::withdraw<T>(portfolio, owner, account_name, amount)
}

public fun withdraw_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    portfolio::withdraw_fee<T>(portfolio, owner, account_name, amount)
}

public fun withdraw_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    amount: Option<u64>,
): Balance<T> {
    portfolio::withdraw_reward<T>(portfolio, owner, account_name, amount)
}

public fun claim<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    portfolio::claim<T>(portfolio, owner, account_name, ctx);
}

public fun claim_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    portfolio::claim_fee<T>(portfolio, owner, account_name, ctx);
}

public fun claim_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
) {
    portfolio::claim_reward<T>(portfolio, owner, account_name, ctx);
}

public fun claim_all<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    portfolio::claim_all<T>(portfolio, owner, ctx);
}

public fun claim_all_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    portfolio::claim_all_fee<T>(portfolio, owner, ctx);
}

public fun claim_all_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    ctx: &mut TxContext,
) {
    portfolio::claim_all_reward<T>(portfolio, owner, ctx);
}
