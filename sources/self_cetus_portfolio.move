/// Module: Self Cetus Portfolio
module terminal::self_cetus_portfolio;

use terminal::cetus_portfolio::CetusPortfolio;

public fun claim_all(portfolio: &mut CetusPortfolio, ctx: &TxContext) {
    portfolio.claim_all(ctx.sender());
}
