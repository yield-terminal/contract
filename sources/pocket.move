/// Module: Pocket
module terminal::pocket;

use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::coin;

public struct Pocket has store {
    bag: Bag,
    coins: vector<TypeName>,
    amounts: vector<u64>,
}

public struct PocketBalance has copy, drop, store {
    coinType: TypeName,
    value: u64,
}

public fun new(ctx: &mut TxContext): Pocket {
    Pocket {
        bag: bag::new(ctx),
        coins: vector::empty<TypeName>(),
        amounts: vector::empty<u64>(),
    }
}

public fun deposit<T>(pocket: &mut Pocket, balance: Balance<T>) {
    if (balance::value(&balance) > 0) {
        let coin_type = type_name::get<T>();
        let pocketBag = &mut pocket.bag;
        if (bag::contains(pocketBag, coin_type)) {
            let current: &mut Balance<T> = bag::borrow_mut(pocketBag, coin_type);
            balance::join(current, balance);
            let coins = &pocket.coins;
            let (_, i) = vector::index_of(coins, &coin_type);
            let amounts = &mut pocket.amounts;
            vector::remove(amounts, i);
            vector::insert(amounts, balance::value(current), i);
        } else {
            let coins = &mut pocket.coins;
            let amounts = &mut pocket.amounts;
            vector::push_back(coins, coin_type);
            vector::push_back(amounts, balance::value(&balance));
            bag::add(pocketBag, coin_type, balance);
        }
    } else {
        balance::destroy_zero(balance);
    }
}

public fun contains<T>(pocket: &Pocket): bool {
    let coin_type = type_name::get<T>();
    let pocketBag = &pocket.bag;
    bag::contains(pocketBag, coin_type)
}

public fun is_empty(pocket: &Pocket): bool {
    let pocketBag = &pocket.bag;
    bag::is_empty(pocketBag)
}

public fun destroy_empty(pocket: Pocket) {
    let Pocket {
        bag,
        coins,
        amounts,
    } = pocket;
    bag::destroy_empty(bag);
    vector::destroy_empty(coins);
    vector::destroy_empty(amounts);
}

public fun withdraw<T>(pocket: &mut Pocket, amount: Option<u64>): Balance<T> {
    if (amount.is_some() && amount.borrow() == 0) {
        balance::zero<T>()
    } else {
        let coin_type = type_name::get<T>();
        let coins = &mut pocket.coins;
        let amounts = &mut pocket.amounts;
        let (_, i) = vector::index_of(coins, &coin_type);
        if (!amount.is_some() || amounts[i] == amount.borrow()) {
            vector::remove(coins, i);
            vector::remove(amounts, i);
            let pocketBag = &mut pocket.bag;
            let value: Balance<T> = bag::remove(pocketBag, coin_type);
            value
        } else {
            let pocketBag = &mut pocket.bag;
            let value: &mut Balance<T> = bag::borrow_mut(pocketBag, coin_type);
            balance::split(value, *amount.borrow())
        }
    }
}

public fun get_balance(pocket: &Pocket): vector<PocketBalance> {
    let mut balances = vector::empty();
    let coins = &pocket.coins;
    let amounts = &pocket.amounts;
    let i = 0;
    let len = coins.length();
    while (i < len) {
        balances.push_back(PocketBalance {
            coinType: coins[i],
            value: amounts[i],
        })
    };
    balances
}

public fun transfer<T>(pocket: &mut Pocket, recipient: address, ctx: &mut TxContext) {
    if (contains<T>(pocket)) {
        let balance: Balance<T> = withdraw(pocket, option::none());
        transfer::public_transfer(coin::from_balance(balance, ctx), recipient);
    }
}
