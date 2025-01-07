/// Module: Cetus Portfolio
module terminal::cetus_portfolio;

use cetus_clmm::position::Position;
use integer_mate::i32::I32;
use std::ascii::String;
use sui::event;
use sui::linked_table::{Self, LinkedTable};
use terminal::utils;

public struct CetusPortfolio has key {
    id: UID,
    positions: LinkedTable<address, LinkedTable<String, LinkedTable<ID, Position>>>,
}

public struct CetusPositionInfo has copy, drop, store {
    id: ID,
    pool_id: ID,
    lower_tick: I32,
    upper_tick: I32,
    liquidity: u128,
}

public struct FetchCetusPositionsEvent has copy, drop, store {
    owner: address,
    account_name: String,
    positions: vector<CetusPositionInfo>,
}

public struct FetchCetusOwnersEvent has copy, drop, store {
    owners: vector<address>,
    total: u64,
}

public struct FetchCetusAccountsEvent has copy, drop, store {
    owner: address,
    accounts: vector<String>,
    total: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(CetusPortfolio {
        id: object::new(ctx),
        positions: linked_table::new<address, LinkedTable<String, LinkedTable<ID, Position>>>(ctx),
    });
}

fun add_owner_if_not_exist(portfolio: &mut CetusPortfolio, owner: address, ctx: &mut TxContext) {
    if (!portfolio.positions.contains(owner)) {
        portfolio
            .positions
            .push_back(
                owner,
                linked_table::new<String, LinkedTable<ID, Position>>(ctx),
            );
    }
}

fun add_account_if_not_exist(
    own_positions: &mut LinkedTable<String, LinkedTable<ID, Position>>,
    account_name: String,
    ctx: &mut TxContext,
) {
    if (!own_positions.contains(account_name)) {
        own_positions.push_back(account_name, linked_table::new<ID, Position>(ctx));
    }
}

fun borrow_or_new_positions_mut(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    ctx: &mut TxContext,
): &mut LinkedTable<ID, Position> {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let own_positions = portfolio.positions.borrow_mut(owner);
    add_account_if_not_exist(own_positions, account_name, ctx);
    own_positions.borrow_mut(account_name)
}

fun borrow_positions_mut(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
): &mut LinkedTable<ID, Position> {
    portfolio.positions.borrow_mut(owner).borrow_mut(account_name)
}

fun borrow_positions(
    portfolio: &CetusPortfolio,
    owner: address,
    account_name: String,
): &LinkedTable<ID, Position> {
    portfolio.positions.borrow(owner).borrow(account_name)
}

fun has_account_positions(portfolio: &CetusPortfolio, owner: address, account_name: String): bool {
    if (portfolio.positions.contains(owner)) {
        let positions = linked_table::borrow(&portfolio.positions, owner);
        linked_table::contains(positions, account_name)
    } else {
        false
    }
}

public(package) fun deposit_position(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position: Position,
    ctx: &mut TxContext,
) {
    let positions = borrow_or_new_positions_mut(portfolio, owner, account_name, ctx);
    positions.push_back(object::id(&position), position);
}

public(package) fun withdraw_position(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): Position {
    let positions = borrow_positions_mut(portfolio, owner, account_name);
    positions.remove(position_id)
}

public(package) fun borrow_position(
    portfolio: &CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &Position {
    borrow_positions(portfolio, owner, account_name).borrow(position_id)
}

public(package) fun borrow_position_mut(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &mut Position {
    borrow_positions_mut(portfolio, owner, account_name).borrow_mut(position_id)
}

public(package) fun claim_all(portfolio: &mut CetusPortfolio, owner: address) {
    let own_positions = portfolio.positions.borrow_mut(owner);
    let mut account_key = own_positions.front();

    while (account_key.is_some()) {
        let account_name = *account_key.borrow();
        let account_positions = own_positions.borrow_mut(account_name);
        let mut position_key = account_positions.front();
        while (position_key.is_some()) {
            let position_id = *position_key.borrow();
            let position = account_positions.remove(position_id);
            transfer::public_transfer(position, owner);
            position_key = account_positions.next(position_id);
        };
        account_key = own_positions.next(account_name);
    };
}

public fun get_positions(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    pool_option: Option<ID>,
): vector<CetusPositionInfo> {
    let mut positions = vector::empty<CetusPositionInfo>();

    if (has_account_positions(portfolio, owner, account_name)) {
        let own_positions = portfolio.positions.borrow(owner);
        let account_positions = own_positions.borrow(account_name);
        let mut position_key = account_positions.front();
        while (position_key.is_some()) {
            let pos_id = *position_key.borrow();
            let position = account_positions.borrow(pos_id);
            let pool_id = position.pool_id();
            if (pool_option.is_none() || pool_option.borrow() == pool_id) {
                let (lower_tick, upper_tick) = position.tick_range();
                let liquidity = position.liquidity();
                positions.push_back(CetusPositionInfo {
                    id: pos_id,
                    pool_id,
                    lower_tick,
                    upper_tick,
                    liquidity,
                });
            };

            position_key = account_positions.next(pos_id);
        };
    };

    positions
}

public fun fetch_positions(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    pool_option: Option<ID>,
) {
    let positions = get_positions(
        portfolio,
        owner,
        account_name,
        pool_option,
    );
    event::emit(FetchCetusPositionsEvent {
        owner,
        account_name,
        positions,
    });
}

public fun get_accounts(
    portfolio: &mut CetusPortfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<String>, u64) {
    if (linked_table::contains(&portfolio.positions, owner)) {
        let own_positions = portfolio.positions.borrow_mut(owner);
        utils::linked_table_limit_keys(own_positions, limit, offset)
    } else {
        (vector::empty<String>(), 0)
    }
}

public fun fetch_accounts(
    portfolio: &mut CetusPortfolio,
    owner: address,
    limit: Option<u64>,
    offset: Option<u64>,
) {
    let (accounts, total) = get_accounts(portfolio, owner, limit, offset);
    event::emit(FetchCetusAccountsEvent {
        owner,
        accounts,
        total,
    });
}

public fun get_owners(
    portfolio: &mut CetusPortfolio,
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<address>, u64) {
    utils::linked_table_limit_keys(&portfolio.positions, limit, offset)
}

public fun fetch_owners(portfolio: &mut CetusPortfolio, limit: Option<u64>, offset: Option<u64>) {
    let (owners, total) = get_owners(portfolio, limit, offset);
    event::emit(FetchCetusOwnersEvent {
        owners,
        total,
    });
}

public fun cleanup(portfolio: &mut CetusPortfolio, owner: address, account_name: String) {
    if (has_account_positions(portfolio, owner, account_name)) {
        let own_positions = portfolio.positions.borrow_mut(owner);
        if (own_positions.borrow(account_name).is_empty()) {
            own_positions.remove(account_name).destroy_empty();
        }
    };
}

public fun cleanup_all(portfolio: &mut CetusPortfolio) {
    let mut owner_key = portfolio.positions.front();
    let mut owner_remove_list = vector::empty<address>();

    while (owner_key.is_some()) {
        let owner = *owner_key.borrow();

        let own_positions = portfolio.positions.borrow_mut(owner);
        let mut account_key = own_positions.front();
        let mut account_remove_list = vector::empty<String>();

        while (account_key.is_some()) {
            let account_name = *account_key.borrow();
            if (own_positions.borrow_mut(account_name).is_empty()) {
                account_remove_list.push_back(account_name);
            };
            account_key = own_positions.next(account_name);
        };

        let mut i = 0;
        while (i < account_remove_list.length()) {
            own_positions.remove(account_remove_list[i]).destroy_empty();
            i = i + 1;
        };

        if (own_positions.is_empty()) {
            owner_remove_list.push_back(owner);
        };

        owner_key = portfolio.positions.next(owner);
    };

    let mut i = 0;
    while (i < owner_remove_list.length()) {
        portfolio.positions.remove(owner_remove_list[i]).destroy_empty();
        i = i + 1;
    };
}
