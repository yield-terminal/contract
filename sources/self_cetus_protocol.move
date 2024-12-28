/// Module: Self Cetus Protocol
module terminal::self_cetus_protocol;

use cetus_clmm::config::GlobalConfig;
use cetus_clmm::pool::Pool;
use cetus_clmm::rewarder::RewarderGlobalVault;
use std::ascii::String;
use sui::clock::Clock;
use terminal::cetus_portfolio::CetusPortfolio;
use terminal::cetus_protocol;
use terminal::portfolio::Portfolio;

fun init(_ctx: &mut TxContext) {}

public fun add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        liquidity,
        clock,
    );
}

public fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        amount,
        fix_amount_a,
        clock,
    );
}

public fun open_position_with_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    tick_lower: u32,
    tick_upper: u32,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::open_position_with_liquidity<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        tick_lower,
        tick_upper,
        liquidity,
        clock,
        ctx,
    );
}

public fun open_position_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    tick_lower: u32,
    tick_upper: u32,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::open_position_fix_coin<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        tick_lower,
        tick_upper,
        amount,
        fix_amount_a,
        clock,
        ctx,
    );
}

public fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::close_position<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        clock,
        ctx,
    );
}

public fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::remove_liquidity<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        liquidity,
        clock,
        ctx,
    );
}

public fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    ctx: &mut TxContext,
) {
    cetus_protocol::collect_fee<CoinTypeA, CoinTypeB>(
        config,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        recalculate,
        ctx,
    );
}

public fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
        config,
        vault,
        portfolio,
        cetus_portfolio,
        pool,
        ctx.sender(),
        account_name,
        position_id,
        recalculate,
        clock,
        ctx,
    );
}

public fun swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    portfolio: &mut Portfolio,
    account_name: String,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    swap_result: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    cetus_protocol::swap<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        ctx.sender(),
        account_name,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        swap_result,
        clock,
        ctx,
    );
}
