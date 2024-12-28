/// Module: Admin Cetus Portfolio
module terminal::admin_cetus_portfolio;

use cetus_clmm::position::Position;
use std::ascii::String;
use terminal::cetus_portfolio::{Self, CetusPortfolio};
use terminal::config::AdminCap;

public fun admin_deposit_position(
    _adminCap: &AdminCap,
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position: Position,
    ctx: &mut TxContext,
) {
    cetus_portfolio::deposit_position(portfolio, owner, account_name, position, ctx);
}

public fun admin_withdraw_position(
    _adminCap: &AdminCap,
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): Position {
    cetus_portfolio::withdraw_position(portfolio, owner, account_name, position_id)
}

public fun admin_borrow_position(
    _adminCap: &AdminCap,
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &Position {
    cetus_portfolio::borrow_position(portfolio, owner, account_name, position_id)
}

public fun admin_borrow_position_mut(
    _adminCap: &AdminCap,
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position_id: ID,
): &mut Position {
    cetus_portfolio::borrow_position_mut(portfolio, owner, account_name, position_id)
}

public fun claim_all(_adminCap: &AdminCap, portfolio: &mut CetusPortfolio, owner: address) {
    cetus_portfolio::claim_all(portfolio, owner);
}
