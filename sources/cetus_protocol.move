/// Module: Cetus Protocol
module terminal::cetus_protocol;

use cetus_clmm::config::GlobalConfig;
use cetus_clmm::pool::{Self, Pool, AddLiquidityReceipt};
use cetus_clmm::position;
use cetus_clmm::rewarder::RewarderGlobalVault;
use std::ascii::String;
use sui::balance;
use sui::clock::Clock;
use terminal::cetus_portfolio::{Self, CetusPortfolio};
use terminal::portfolio::{Self, Portfolio};

public struct SwapResult has copy, drop, store {
    amount_in: u64,
    amount_out: u64,
}

public struct AmountResult has copy, drop, store {
    amount_a: u64,
    amount_b: u64,
}

public struct OpenPositionResult has copy, drop, store {
    pos_id: ID,
    amount_a: u64,
    amount_b: u64,
}

fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
): AmountResult {
    let (amount_a, amount_b) = pool::add_liquidity_pay_amount(&receipt);
    let balance_a = portfolio::withdraw<CoinTypeA>(
        portfolio,
        owner,
        account_name,
        option::some(amount_a),
    );
    let balance_b = portfolio::withdraw<CoinTypeB>(
        portfolio,
        owner,
        account_name,
        option::some(amount_b),
    );
    pool::repay_add_liquidity(config, pool, balance_a, balance_b, receipt);
    AmountResult { amount_a, amount_b }
}

public(package) fun add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    liquidity: u128,
    clock: &Clock,
): AmountResult {
    let position = cetus_portfolio::borrow_position_mut(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let receipt = pool::add_liquidity(
        config,
        pool,
        position,
        liquidity,
        clock,
    );
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt)
}

public(package) fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
): AmountResult {
    let position = cetus_portfolio::borrow_position_mut(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        position,
        amount,
        fix_amount_a,
        clock,
    );
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt)
}

public(package) fun open_position_with_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    tick_lower: u32,
    tick_upper: u32,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): OpenPositionResult {
    let mut position = pool::open_position(
        config,
        pool,
        tick_lower,
        tick_upper,
        ctx,
    );
    let receipt = pool::add_liquidity(
        config,
        pool,
        &mut position,
        liquidity,
        clock,
    );
    let amount_result = repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
    let pos_id = object::id(&position);
    let AmountResult { amount_a, amount_b } = amount_result;
    cetus_portfolio::deposit_position(cetus_portfolio, owner, account_name, position, ctx);
    OpenPositionResult { pos_id, amount_a, amount_b }
}

public(package) fun open_position_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    tick_lower: u32,
    tick_upper: u32,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): OpenPositionResult {
    let mut position = pool::open_position(
        config,
        pool,
        tick_lower,
        tick_upper,
        ctx,
    );
    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        &mut position,
        amount,
        fix_amount_a,
        clock,
    );
    let amount_result = repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
    let pos_id = object::id(&position);
    let AmountResult { amount_a, amount_b } = amount_result;
    cetus_portfolio::deposit_position(cetus_portfolio, owner, account_name, position, ctx);
    OpenPositionResult { pos_id, amount_a, amount_b }
}

public(package) fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    clock: &Clock,
    ctx: &mut TxContext,
): AmountResult {
    let mut position = cetus_portfolio::withdraw_position(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let liquidity = position::liquidity(&position);
    let mut amount_a = 0;
    let mut amount_b = 0;
    if (liquidity > 0) {
        let (balance_a, balance_b) = pool::remove_liquidity<CoinTypeA, CoinTypeB>(
            config,
            pool,
            &mut position,
            liquidity,
            clock,
        );
        amount_a = balance_a.value();
        amount_b = balance_b.value();
        portfolio::deposit<CoinTypeA>(portfolio, owner, account_name, balance_a, ctx);
        portfolio::deposit<CoinTypeB>(portfolio, owner, account_name, balance_b, ctx);
    };
    pool::close_position<CoinTypeA, CoinTypeB>(config, pool, position);
    AmountResult { amount_a, amount_b }
}

public(package) fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): AmountResult {
    let position = cetus_portfolio::borrow_position_mut(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let (balance_a, balance_b) = pool::remove_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position,
        liquidity,
        clock,
    );
    let amount_a = balance_a.value();
    let amount_b = balance_b.value();
    portfolio::deposit<CoinTypeA>(portfolio, owner, account_name, balance_a, ctx);
    portfolio::deposit<CoinTypeB>(portfolio, owner, account_name, balance_b, ctx);
    AmountResult { amount_a, amount_b }
}

public(package) fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    ctx: &mut TxContext,
): AmountResult {
    let position = cetus_portfolio::borrow_position(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let (fee_a, fee_b) = pool::collect_fee(
        config,
        pool,
        position,
        recalculate,
    );
    let amount_a = fee_a.value();
    let amount_b = fee_b.value();
    portfolio::deposit_fee<CoinTypeA>(portfolio, owner, account_name, fee_a, ctx);
    portfolio::deposit_fee<CoinTypeB>(portfolio, owner, account_name, fee_b, ctx);
    AmountResult { amount_a, amount_b }
}

public(package) fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): u64 {
    let position = cetus_portfolio::borrow_position(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let reward_balance = pool::collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
        config,
        pool,
        position,
        vault,
        recalculate,
        clock,
    );
    let amount = reward_balance.value();
    portfolio::deposit_reward<CoinTypeC>(portfolio, owner, account_name, reward_balance, ctx);
    amount
}

public(package) fun swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): SwapResult {
    // flash swap first
    let (receive_a, receive_b, flash_receipt) = pool::flash_swap<CoinTypeA, CoinTypeB>(
        config,
        pool,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    );
    let (amount_in, amount_out) = (
        pool::swap_pay_amount(&flash_receipt),
        if (a2b) balance::value(&receive_b) else balance::value(&receive_a),
    );

    // pay for flash swap
    let (pay_coin_a, pay_coin_b) = if (a2b) {
        (
            portfolio::withdraw<CoinTypeA>(
                portfolio,
                owner,
                account_name,
                option::some(amount_in),
            ),
            balance::zero<CoinTypeB>(),
        )
    } else {
        (
            balance::zero<CoinTypeA>(),
            portfolio::withdraw<CoinTypeB>(
                portfolio,
                owner,
                account_name,
                option::some(amount_in),
            ),
        )
    };

    portfolio::deposit<CoinTypeB>(
        portfolio,
        owner,
        account_name,
        receive_b,
        ctx,
    );
    portfolio::deposit<CoinTypeA>(
        portfolio,
        owner,
        account_name,
        receive_a,
        ctx,
    );

    pool::repay_flash_swap<CoinTypeA, CoinTypeB>(
        config,
        pool,
        pay_coin_a,
        pay_coin_b,
        flash_receipt,
    );

    SwapResult { amount_in, amount_out }
}
