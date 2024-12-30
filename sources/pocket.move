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
    if (balance::value(&balance) > 0) {
        let coin_type = type_name::get<T>();
        let pocketBag = &mut pocket.bag;
        let balances = &mut pocket.balances;
        if (bag::contains(pocketBag, coin_type)) {
            let current: &mut Balance<T> = bag::borrow_mut(pocketBag, coin_type);
            balance::join(current, balance);
            let i = balances.find_index!(|b| b.coin_type == coin_type);
            let coin_balance = balances.borrow_mut(*i.borrow());
            coin_balance.value = current.value();
        } else {
            balances.push_back(CoinBalance {
                coin_type,
                value: balance.value(),
            });
            bag::add(pocketBag, coin_type, balance);
        }
    } else {
        balance::destroy_zero(balance);
    }
}

public fun withdraw<T>(pocket: &mut Pocket, amount: Option<u64>): Balance<T> {
    if (amount.is_some() && amount.borrow() == 0) {
        balance::zero<T>()
    } else {
        let coin_type = type_name::get<T>();
        let pocketBag = &mut pocket.bag;
        let balances = &mut pocket.balances;
        let balance: &Balance<T> = bag::borrow(pocketBag, coin_type);
        if (amount.is_none() || balance.value() == amount.borrow()) {
            let i = balances.find_index!(|b| b.coin_type == coin_type);
            balances.remove(*i.borrow());
            bag::remove(pocketBag, coin_type)
        } else {
            let pocketBag = &mut pocket.bag;
            let current: &mut Balance<T> = bag::borrow_mut(pocketBag, coin_type);
            balance::split(current, *amount.borrow())
        }
    }
}

public fun get_all_balances(pocket: &Pocket): vector<CoinBalance> {
    pocket.balances
}

public fun contains<T>(pocket: &Pocket): bool {
    let coin_type = type_name::get<T>();
    bag::contains(&pocket.bag, coin_type)
}

public fun is_empty(pocket: &Pocket): bool {
    bag::is_empty(&pocket.bag)
}

public fun destroy_empty(pocket: Pocket) {
    let Pocket {
        bag,
        balances,
    } = pocket;
    bag::destroy_empty(bag);
    vector::destroy_empty(balances);
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
    if (bag::contains(&pocket.bag, coin_type)) {
        let balance: &Balance<T> = bag::borrow(&pocket.bag, coin_type);
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
        let balance: Balance<T> = withdraw(pocket, option::none());
        transfer::public_transfer(coin::from_balance(balance, ctx), recipient);
    }
}
