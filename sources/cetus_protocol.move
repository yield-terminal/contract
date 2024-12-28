/// Module: Cetus Protocol
module terminal::cetus_protocol;

use cetus_clmm::config::GlobalConfig;
use cetus_clmm::pool::{Self, Pool, AddLiquidityReceipt};
use cetus_clmm::position;
use cetus_clmm::rewarder::RewarderGlobalVault;
use std::ascii::String;
use sui::clock::Clock;
use terminal::cetus_portfolio::{Self, CetusPortfolio};
use terminal::portfolio::{Self, Portfolio};

fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
) {
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
) {
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
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
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
) {
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
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
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
) {
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
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
    cetus_portfolio::deposit_position(cetus_portfolio, owner, account_name, position, ctx);
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
) {
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
    repay_add_liquidity(config, pool, portfolio, owner, account_name, receipt);
    cetus_portfolio::deposit_position(cetus_portfolio, owner, account_name, position, ctx);
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
) {
    let mut position = cetus_portfolio::withdraw_position(
        cetus_portfolio,
        owner,
        account_name,
        position_id,
    );
    let liquidity = position::liquidity(&position);
    if (liquidity > 0) {
        let (balance_a, balance_b) = pool::remove_liquidity<CoinTypeA, CoinTypeB>(
            config,
            pool,
            &mut position,
            liquidity,
            clock,
        );
        portfolio::deposit<CoinTypeA>(portfolio, owner, account_name, balance_a, ctx);
        portfolio::deposit<CoinTypeB>(portfolio, owner, account_name, balance_b, ctx);
    };
    pool::close_position<CoinTypeA, CoinTypeB>(config, pool, position);
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
) {
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
    portfolio::deposit<CoinTypeA>(portfolio, owner, account_name, balance_a, ctx);
    portfolio::deposit<CoinTypeB>(portfolio, owner, account_name, balance_b, ctx);
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
) {
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
    portfolio::deposit_fee<CoinTypeA>(portfolio, owner, account_name, fee_a, ctx);
    portfolio::deposit_fee<CoinTypeB>(portfolio, owner, account_name, fee_b, ctx);
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
) {
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
    portfolio::deposit_reward<CoinTypeC>(portfolio, owner, account_name, reward_balance, ctx);
}
