/// Module: Cetus Protocol
module terminal::cetus_protocol;

use cetus_clmm::clmm_math;
use cetus_clmm::config::GlobalConfig;
use cetus_clmm::pool::{Self, Pool, AddLiquidityReceipt};
use cetus_clmm::position::Position;
use cetus_clmm::rewarder::RewarderGlobalVault;
use cetus_clmm::tick_math;
use std::ascii::String;
use std::type_name::{Self, TypeName};
use sui::balance;
use sui::clock::Clock;
use sui::event;
use terminal::cetus_portfolio::CetusPortfolio;
use terminal::portfolio::Portfolio;

const EOverMaxAmount: u64 = 0;
const ELiquidityZero: u64 = 1;

public struct SwapResult has copy, drop, store {
    fee_amount: u64,
    before_sqrt_price: u128,
    after_sqrt_price: u128,
}

public struct SwapEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    a2b: bool,
    amount_in: u64,
    amount_out: u64,
    result: Option<SwapResult>,
}

public struct CollectRewardEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type: TypeName,
    amount: u64,
}

public struct CollectFeeEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    amount_a: u64,
    amount_b: u64,
}

public struct RemoveLiquidityEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    amount_a: u64,
    amount_b: u64,
}

public struct ClosePositionEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    amount_a: u64,
    amount_b: u64,
}

public struct OpenPositionEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    amount_a: u64,
    amount_b: u64,
}

public struct AddLiquidityEvent has copy, drop, store {
    owner: address,
    account_name: String,
    pool_id: ID,
    position_id: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    amount_a: u64,
    amount_b: u64,
}

fun get_portfolio_amounts<CoinTypeA, CoinTypeB>(
    portfolio: &Portfolio,
    owner: address,
    account_name: String,
    max_amount_a: Option<u64>,
    max_amount_b: Option<u64>,
): (u64, u64) {
    let (value_a, value_b) = portfolio.get_pool_amounts<CoinTypeA, CoinTypeB>(
        owner,
        account_name,
    );
    let amount_a = if (max_amount_a.is_some() && *max_amount_a.borrow() < value_a) {
        *max_amount_a.borrow()
    } else {
        value_a
    };
    let amount_b = if (max_amount_a.is_some() && *max_amount_b.borrow() < value_b) {
        *max_amount_b.borrow()
    } else {
        value_b
    };

    (amount_a, amount_b)
}

fun calculate_liquidity<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position: &Position,
    amount_a: u64,
    amount_b: u64,
): u128 {
    let current_tick = pool.current_tick_index();
    let current_sqrt_price = pool.current_sqrt_price();
    let (lower_index, upper_index) = position.tick_range();
    let lower_sqrt_price = tick_math::get_sqrt_price_at_tick(lower_index);
    let upper_sqrt_price = tick_math::get_sqrt_price_at_tick(upper_index);

    if (current_tick.lt(lower_index)) {
        return clmm_math::get_liquidity_from_a(lower_sqrt_price, upper_sqrt_price, amount_a, false)
    };
    if (current_tick.gte(upper_index)) {
        return clmm_math::get_liquidity_from_a(upper_sqrt_price, lower_sqrt_price, amount_b, false)
    };
    let liquidity_a = clmm_math::get_liquidity_from_a(
        current_sqrt_price,
        upper_sqrt_price,
        amount_a,
        false,
    );
    let liquidity_b = clmm_math::get_liquidity_from_a(
        current_sqrt_price,
        lower_sqrt_price,
        amount_b,
        false,
    );

    if (liquidity_a < liquidity_b) { liquidity_a } else { liquidity_b }
}

fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    portfolio: &mut Portfolio,
    owner: address,
    account_name: String,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
): (u64, u64) {
    let (amount_a, amount_b) = pool::add_liquidity_pay_amount<CoinTypeA, CoinTypeB>(&receipt);
    let balance_a = portfolio.withdraw<CoinTypeA>(
        owner,
        account_name,
        option::some(amount_a),
    );
    let balance_b = portfolio.withdraw<CoinTypeB>(
        owner,
        account_name,
        option::some(amount_b),
    );
    pool::repay_add_liquidity<CoinTypeA, CoinTypeB>(config, pool, balance_a, balance_b, receipt);

    (amount_a, amount_b)
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
    let position = cetus_portfolio.borrow_position_mut(
        owner,
        account_name,
        position_id,
    );
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position,
        liquidity,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );

    event::emit(AddLiquidityEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
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
    let position = cetus_portfolio.borrow_position_mut(
        owner,
        account_name,
        position_id,
    );
    let receipt = pool::add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position,
        amount,
        fix_amount_a,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );

    event::emit(AddLiquidityEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
}

public(package) fun add_liquidity_by_max_amount<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    max_amount_a: Option<u64>,
    max_amount_b: Option<u64>,
    clock: &Clock,
) {
    let position = cetus_portfolio.borrow_position_mut(
        owner,
        account_name,
        position_id,
    );
    let (p_amount_a, p_amount_b) = get_portfolio_amounts<CoinTypeA, CoinTypeB>(
        portfolio,
        owner,
        account_name,
        max_amount_a,
        max_amount_b,
    );
    let liquidity = calculate_liquidity(pool, position, p_amount_a, p_amount_b);
    assert!(liquidity > 0, ELiquidityZero);
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position,
        liquidity,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );

    event::emit(AddLiquidityEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
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
    let mut position = pool::open_position<CoinTypeA, CoinTypeB>(
        config,
        pool,
        tick_lower,
        tick_upper,
        ctx,
    );
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        &mut position,
        liquidity,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );
    let position_id = object::id(&position);
    cetus_portfolio.deposit_position(owner, account_name, position, ctx);

    event::emit(OpenPositionEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
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
    let mut position = pool::open_position<CoinTypeA, CoinTypeB>(
        config,
        pool,
        tick_lower,
        tick_upper,
        ctx,
    );
    let receipt = pool::add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
        config,
        pool,
        &mut position,
        amount,
        fix_amount_a,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );
    let position_id = object::id(&position);
    cetus_portfolio.deposit_position(owner, account_name, position, ctx);

    event::emit(OpenPositionEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
}

public(package) fun open_position_by_max_amount<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    tick_lower: u32,
    tick_upper: u32,
    max_amount_a: Option<u64>,
    max_amount_b: Option<u64>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let mut position = pool::open_position<CoinTypeA, CoinTypeB>(
        config,
        pool,
        tick_lower,
        tick_upper,
        ctx,
    );
    let (p_amount_a, p_amount_b) = get_portfolio_amounts<CoinTypeA, CoinTypeB>(
        portfolio,
        owner,
        account_name,
        max_amount_a,
        max_amount_b,
    );
    let liquidity = calculate_liquidity(pool, &position, p_amount_a, p_amount_b);
    assert!(liquidity > 0, ELiquidityZero);
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        &mut position,
        liquidity,
        clock,
    );
    let (amount_a, amount_b) = repay_add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        portfolio,
        owner,
        account_name,
        receipt,
    );
    let position_id = object::id(&position);
    cetus_portfolio.deposit_position(owner, account_name, position, ctx);

    event::emit(OpenPositionEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
}

public(package) fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &mut CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    max_amount_a: Option<u64>,
    max_amount_b: Option<u64>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let mut position = cetus_portfolio.withdraw_position(
        owner,
        account_name,
        position_id,
    );
    let liquidity = position.liquidity();
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
        assert!(max_amount_a.is_none() || amount_a <= *max_amount_a.borrow(), EOverMaxAmount);
        assert!(max_amount_b.is_none() || amount_b <= *max_amount_b.borrow(), EOverMaxAmount);
        portfolio.deposit<CoinTypeA>(owner, account_name, balance_a, ctx);
        portfolio.deposit<CoinTypeB>(owner, account_name, balance_b, ctx);
    };
    pool::close_position<CoinTypeA, CoinTypeB>(config, pool, position);

    event::emit(ClosePositionEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
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
    max_amount_a: Option<u64>,
    max_amount_b: Option<u64>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let position = cetus_portfolio.borrow_position_mut(
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
    assert!(max_amount_a.is_none() || amount_a <= *max_amount_a.borrow(), EOverMaxAmount);
    assert!(max_amount_b.is_none() || amount_b <= *max_amount_b.borrow(), EOverMaxAmount);
    portfolio.deposit<CoinTypeA>(owner, account_name, balance_a, ctx);
    portfolio.deposit<CoinTypeB>(owner, account_name, balance_b, ctx);

    event::emit(RemoveLiquidityEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
}

public(package) fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    portfolio: &mut Portfolio,
    cetus_portfolio: &CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    ctx: &mut TxContext,
) {
    let position = cetus_portfolio.borrow_position(
        owner,
        account_name,
        position_id,
    );
    let (fee_a, fee_b) = pool::collect_fee<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position,
        recalculate,
    );
    let amount_a = fee_a.value();
    let amount_b = fee_b.value();
    portfolio.deposit_fee<CoinTypeA>(owner, account_name, fee_a, ctx);
    portfolio.deposit_fee<CoinTypeB>(owner, account_name, fee_b, ctx);

    event::emit(CollectFeeEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        amount_a,
        amount_b,
    });
}

public(package) fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    portfolio: &mut Portfolio,
    cetus_portfolio: &CetusPortfolio,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    owner: address,
    account_name: String,
    position_id: ID,
    recalculate: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let position = cetus_portfolio.borrow_position(
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
    portfolio.deposit_reward<CoinTypeC>(owner, account_name, reward_balance, ctx);

    event::emit(CollectRewardEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        position_id,
        coin_type: type_name::get<CoinTypeC>(),
        amount,
    });
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
    swap_result: bool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let before_sqrt_price = pool.current_sqrt_price();
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

    let mut result = option::none<SwapResult>();

    if (swap_result) {
        let swap_result = pool::calculate_swap_result<CoinTypeA, CoinTypeB>(
            pool,
            a2b,
            by_amount_in,
            amount,
        );
        let fee_amount = pool::calculated_swap_result_fee_amount(&swap_result);
        let after_sqrt_price = pool::calculated_swap_result_after_sqrt_price(&swap_result);
        result =
            option::some(SwapResult {
                fee_amount,
                before_sqrt_price,
                after_sqrt_price,
            })
    };

    // pay for flash swap
    let (pay_coin_a, pay_coin_b) = if (a2b) {
        (
            portfolio.withdraw<CoinTypeA>(
                owner,
                account_name,
                option::some(amount_in),
            ),
            balance::zero<CoinTypeB>(),
        )
    } else {
        (
            balance::zero<CoinTypeA>(),
            portfolio.withdraw<CoinTypeB>(
                owner,
                account_name,
                option::some(amount_in),
            ),
        )
    };

    portfolio.deposit<CoinTypeB>(
        owner,
        account_name,
        receive_b,
        ctx,
    );
    portfolio.deposit<CoinTypeA>(
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

    event::emit(SwapEvent {
        owner,
        account_name,
        pool_id: object::id(pool),
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        a2b,
        amount_in,
        amount_out,
        result,
    });
}
