/// Module: Pocket
module terminal::pocket;

use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::coin;

public struct Pocket has store {
    bag: Bag,
    balances: vector<CoinBalance>,
}

public struct CoinBalance has copy, drop, store {
    coin_type: TypeName,
    value: u64,
}

public fun new(ctx: &mut TxContext): Pocket {
    Pocket {
        bag: bag::new(ctx),
        balances: vector::empty<CoinBalance>(),
    }
}

public fun deposit<T>(pocket: &mut Pocket, balance: Balance<T>) {
    if (balance.value() > 0) {
        let coin_type = type_name::get<T>();
        let bag = &mut pocket.bag;
        let balances = &mut pocket.balances;
        if (bag.contains(coin_type)) {
            let current: &mut Balance<T> = bag.borrow_mut(coin_type);
            let i = balances.find_index!(|b| b.coin_type == coin_type);
            let coin_balance = balances.borrow_mut(*i.borrow());
            coin_balance.value = current.join(balance);
        } else {
            balances.push_back(CoinBalance {
                coin_type,
                value: balance.value(),
            });
            bag.add(coin_type, balance);
        }
    } else {
        balance.destroy_zero();
    }
}

public fun withdraw<T>(pocket: &mut Pocket, amount: Option<u64>): Balance<T> {
    if (amount.is_some() && amount.borrow() == 0) return balance::zero<T>();

    let coin_type = type_name::get<T>();
    let bag = &mut pocket.bag;

    if (!bag.contains(coin_type)) return balance::zero<T>();

    let balances = &mut pocket.balances;
    let balance: &Balance<T> = bag.borrow(coin_type);

    if (amount.is_none() || balance.value() == amount.borrow()) {
        let i = balances.find_index!(|b| b.coin_type == coin_type);
        balances.remove(*i.borrow());
        bag.remove(coin_type)
    } else {
        let current: &mut Balance<T> = bag.borrow_mut(coin_type);
        balance::split(current, *amount.borrow())
    }
}

public fun withdraw_all<T>(pocket: &mut Pocket): Balance<T> {
    pocket.withdraw<T>(option::none())
}

public fun get_all_balances(pocket: &Pocket): vector<CoinBalance> {
    pocket.balances
}

public fun contains<T>(pocket: &Pocket): bool {
    let coin_type = type_name::get<T>();
    pocket.bag.contains(coin_type)
}

public fun is_empty(pocket: &Pocket): bool {
    pocket.bag.is_empty()
}

public fun destroy_empty(pocket: Pocket) {
    let Pocket {
        bag,
        balances,
    } = pocket;
    bag.destroy_empty();
    balances.destroy_empty();
}

public fun zero_balance<T>(): CoinBalance {
    let coin_type = type_name::get<T>();
    CoinBalance {
        coin_type,
        value: 0,
    }
}

public fun get_balance<T>(pocket: &Pocket): CoinBalance {
    let coin_type = type_name::get<T>();
    if (pocket.bag.contains(coin_type)) {
        let balance: &Balance<T> = pocket.bag.borrow(coin_type);
        CoinBalance {
            coin_type,
            value: balance.value(),
        }
    } else {
        zero_balance<T>()
    }
}

public fun get_pool_balance<A, B>(pocket: &Pocket): (CoinBalance, CoinBalance) {
    (get_balance<A>(pocket), get_balance<B>(pocket))
}

public fun transfer<T>(pocket: &mut Pocket, recipient: address, ctx: &mut TxContext) {
    if (contains<T>(pocket)) {
        let balance: Balance<T> = pocket.withdraw_all<T>();
        transfer::public_transfer(balance.into_coin(ctx), recipient);
    }
}
