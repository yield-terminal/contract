/// Module: Utils
module terminal::utils;

use sui::linked_table::LinkedTable;

const EINDEX_OUT_OF_BOUNDS: u64 = 1;

public struct KeysPage<K: copy + drop + store> has copy, drop, store {
    items: vector<K>,
    total: u64,
}

public fun linked_table_keys<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
): vector<K> {
    let mut keys = vector::empty<K>();
    let mut option_key = linked_table.front();

    while (option_key.is_some()) {
        let key = *option_key.borrow();
        keys.push_back(key);
        option_key = linked_table.next(key);
    };

    keys
}

public fun linked_table_limit_keys<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
    offset: u64,
    limit: u64,
): vector<K> {
    let total = linked_table.length();
    let mut keys = vector::empty<K>();

    if (offset < total && limit > 0) {
        let mut option_key = &option::some(linked_table_key_of(linked_table, offset));

        while (option_key.is_some() && keys.length() < limit) {
            let key = *option_key.borrow();
            keys.push_back(key);
            option_key = linked_table.next(key);
        };
    };

    keys
}

public fun linked_table_key_of<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
    index: u64,
): K {
    let total = linked_table.length();
    assert!(index < total, EINDEX_OUT_OF_BOUNDS);
    if (index == total - 1) return *linked_table.back().borrow();

    let mut i = 0;
    let mut key = *linked_table.front().borrow();
    while (i != index) {
        key = *linked_table.next(key).borrow();
        i = i + 1;
    };

    key
}

public fun linked_table_keys_page<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
    offset: u64,
    limit: u64,
): KeysPage<K> {
    KeysPage {
        items: linked_table_limit_keys(linked_table, offset, limit),
        total: linked_table.length(),
    }
}
