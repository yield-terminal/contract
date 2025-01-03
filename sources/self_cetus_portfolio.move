/// Module: Self Cetus Portfolio
module terminal::self_cetus_portfolio;

use cetus_clmm::position::Position;
use std::ascii::String;
use terminal::cetus_portfolio::CetusPortfolio;

public(package) fun deposit_position(
    portfolio: &mut CetusPortfolio,
    account_name: String,
    position: Position,
    ctx: &mut TxContext,
) {
    portfolio.deposit_position(ctx.sender(), account_name, position, ctx);
}

public fun claim_all(portfolio: &mut CetusPortfolio, ctx: &TxContext) {
    portfolio.claim_all(ctx.sender());
}
