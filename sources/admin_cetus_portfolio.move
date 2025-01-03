/// Module: Admin Cetus Portfolio
module terminal::admin_cetus_portfolio;

use cetus_clmm::position::Position;
use std::ascii::String;
use terminal::cetus_portfolio::CetusPortfolio;
use terminal::config::AdminCap;

public(package) fun deposit_position(
    _adminCap: &AdminCap, 
    portfolio: &mut CetusPortfolio,
    owner: address,
    account_name: String,
    position: Position,
    ctx: &mut TxContext,
) {
    portfolio.deposit_position(owner, account_name, position, ctx);
}

public fun claim_all(_adminCap: &AdminCap, portfolio: &mut CetusPortfolio, owner: address) {
    portfolio.claim_all(owner);
}
