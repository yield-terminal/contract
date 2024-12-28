/// Module: Cetus Portfolio
module terminal::cetus_portfolio;

use cetus_clmm::position::Position;
use std::ascii::String;
use sui::linked_table::{Self, LinkedTable};
use terminal::utils::{Self, KeysPage};

public struct CetusPortfolio has key {
    id: UID,
    positions: LinkedTable<address, LinkedTable<String, LinkedTable<ID, Position>>>,
}

public struct CetusBalance has copy, drop, store {
    account_name: String,
    positions: vector<ID>,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(CetusPortfolio {
        id: object::new(ctx),
        positions: linked_table::new<address, LinkedTable<String, LinkedTable<ID, Position>>>(ctx),
    });
}

fun add_owner_if_not_exist(portfolio: &mut CetusPortfolio, owner: address, ctx: &mut TxContext) {
    if (!linked_table::contains(&portfolio.positions, owner)) {
        linked_table::push_back(
            &mut portfolio.positions,
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
    if (!linked_table::contains(own_positions, account_name)) {
        linked_table::push_back(own_positions, account_name, linked_table::new<ID, Position>(ctx));
    }
}

public(package) fun deposit_position(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position: Position,
    ctx: &mut TxContext,
) {
    add_owner_if_not_exist(portfolio, owner, ctx);
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    add_account_if_not_exist(own_positions, account_name, ctx);
    let account_positions = linked_table::borrow_mut(own_positions, account_name);
    let id = object::id(&position);
    linked_table::push_back(account_positions, id, position);
}

public(package) fun withdraw_position(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): Position {
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    let account_positions = linked_table::borrow_mut(own_positions, account_name);
    linked_table::remove(account_positions, position_id)
}

public(package) fun borrow_position(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &Position {
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    let account_positions = linked_table::borrow_mut(own_positions, account_name);
    linked_table::borrow(account_positions, position_id)
}

public(package) fun borrow_position_mut(
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &mut Position {
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    let account_positions = linked_table::borrow_mut(own_positions, account_name);
    linked_table::borrow_mut(account_positions, position_id)
}

public(package) fun claim_all(portfolio: &mut CetusPortfolio, owner: address) {
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    let mut account_key = own_positions.front();

    while (account_key.is_some()) {
        let account_name = *account_key.borrow();
        let account_positions = linked_table::borrow_mut(own_positions, account_name);
        let mut position_key = account_positions.front();
        while (position_key.is_some()) {
            let position_id = *position_key.borrow();
            let position = linked_table::remove(account_positions, position_id);
            transfer::public_transfer(position, owner);
            position_key = account_positions.next(position_id);
        };
        account_key = own_positions.next(account_name);
    };
}

public fun get_balances(portfolio: &mut CetusPortfolio, owner: address): vector<CetusBalance> {
    let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
    let mut balances = vector::empty<CetusBalance>();
    let mut option_key = own_positions.front();

    while (option_key.is_some()) {
        let account_name = *option_key.borrow();
        let account_positions = linked_table::borrow(own_positions, account_name);
        balances.push_back(CetusBalance {
            account_name,
            positions: utils::linked_table_keys(account_positions),
        });
        option_key = own_positions.next(account_name);
    };

    balances
}

public fun get_accounts(portfolio: &mut CetusPortfolio, owner: address): vector<String> {
    if (linked_table::contains(&portfolio.positions, owner)) {
        let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);
        utils::linked_table_keys(own_positions)
    } else {
        vector::empty<String>()
    }
}

public fun get_owners(portfolio: &mut CetusPortfolio): vector<address> {
    utils::linked_table_keys(&portfolio.positions)
}

public fun get_owners_page(
    portfolio: &mut CetusPortfolio,
    offset: u64,
    limit: u64,
): KeysPage<address> {
    utils::linked_table_keys_page(&portfolio.positions, offset, limit)
}

public fun cleanup(portfolio: &mut CetusPortfolio, owner: address) {
    if (linked_table::contains(&portfolio.positions, owner)) {
        let accounts = get_accounts(portfolio, owner);
        let own_positions = linked_table::borrow_mut(&mut portfolio.positions, owner);

        let mut i = 0;
        while (i < accounts.length()) {
            let account_positions = linked_table::borrow_mut(own_positions, accounts[i]);
            if (linked_table::is_empty(account_positions)) {
                let positions = linked_table::remove(own_positions, accounts[i]);
                linked_table::destroy_empty(positions);
            };
            i = i + 1;
        };

        if (linked_table::is_empty(own_positions)) {
            let positions = linked_table::remove(&mut portfolio.positions, owner);
            linked_table::destroy_empty(positions);
        };
    }
}
