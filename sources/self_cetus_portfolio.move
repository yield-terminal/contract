/// Module: Self Cetus Portfolio
module terminal::self_cetus_portfolio;

use terminal::cetus_portfolio::{Self, CetusPortfolio};

public fun claim_all(portfolio: &mut CetusPortfolio, ctx: &TxContext) {
    cetus_portfolio::claim_all(portfolio, ctx.sender());
}
