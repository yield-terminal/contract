/// Module: Self Portfolio
module terminal::self_portfolio;

use std::ascii::String;
use sui::coin::{Self, Coin};
use terminal::portfolio::Portfolio;

public fun deposit<T>(
    portfolio: &mut Portfolio,
    account_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext,
) {
    portfolio.deposit<T>(ctx.sender(), account_name, coin::into_balance(coin), ctx);
}

public fun apply_fee<T>(portfolio: &mut Portfolio, account_name: String, ctx: &mut TxContext) {
    portfolio.apply_fee<T>(ctx.sender(), account_name);
}

public fun apply_reward<T>(portfolio: &mut Portfolio, account_name: String, ctx: &mut TxContext) {
    portfolio.apply_reward<T>(ctx.sender(), account_name);
}

public fun claim<T>(portfolio: &mut Portfolio, account_name: String, ctx: &mut TxContext) {
    portfolio.claim<T>(ctx.sender(), account_name, ctx);
}

public fun claim_fee<T>(portfolio: &mut Portfolio, account_name: String, ctx: &mut TxContext) {
    portfolio.claim_fee<T>(ctx.sender(), account_name, ctx);
}

public fun claim_reward<T>(portfolio: &mut Portfolio, account_name: String, ctx: &mut TxContext) {
    portfolio.claim_reward<T>(ctx.sender(), account_name, ctx);
}

public fun claim_all<T>(portfolio: &mut Portfolio, ctx: &mut TxContext) {
    portfolio.claim_all<T>(ctx.sender(), ctx);
}

public fun claim_all_fee<T>(portfolio: &mut Portfolio, ctx: &mut TxContext) {
    portfolio.claim_all_fee<T>(ctx.sender(), ctx);
}

public fun claim_all_reward<T>(portfolio: &mut Portfolio, ctx: &mut TxContext) {
    portfolio.claim_all_reward<T>(ctx.sender(), ctx);
}
