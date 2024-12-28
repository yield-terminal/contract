/// Module: Admin Cetus Portfolio
module terminal::admin_cetus_portfolio;

use terminal::cetus_portfolio::{Self, CetusPortfolio};
use terminal::config::AdminCap;

public fun claim_all(_adminCap: &AdminCap, portfolio: &mut CetusPortfolio, owner: address) {
    cetus_portfolio::claim_all(portfolio, owner);
}
