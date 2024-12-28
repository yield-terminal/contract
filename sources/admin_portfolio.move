/// Module: Admin Portfolio
module terminal::admin_portfolio;

use std::ascii::String;
use sui::coin::{Self, Coin};
use terminal::config::AdminCap;
use terminal::portfolio::{Self, Portfolio};

public fun deposit<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit<T>(portfolio, owner, account_name, coin::into_balance(coin), ctx);
}

public fun deposit_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit_fee<T>(portfolio, owner, account_name, coin::into_balance(coin), ctx);
}

public fun deposit_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext,
) {
    portfolio::deposit_reward<T>(portfolio, owner, account_name, coin::into_balance(coin), ctx);
}

public fun apply_fee<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
) {
    portfolio::apply_fee<T>(portfolio, owner, account_name);
}

public fun apply_reward<T>(
    _adminCap: &AdminCap,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
) {
    portfolio::apply_reward<T>(portfolio, owner, account_name);
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
