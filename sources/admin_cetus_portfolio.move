/// Module: Admin Cetus Portfolio
module terminal::admin_cetus_portfolio;

use terminal::cetus_portfolio::CetusPortfolio;
use terminal::config::AdminCap;

public fun claim_all(_adminCap: &AdminCap, portfolio: &mut CetusPortfolio, owner: address) {
    portfolio.claim_all(owner);
}
