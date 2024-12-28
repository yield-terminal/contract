/// Module: Utils
module terminal::utils;

use sui::linked_table::LinkedTable;

const EINDEX_OUT_OF_BOUNDS: u64 = 1;

public fun linked_table_keys<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
): vector<K> {
    let mut keys = vector::empty<K>();
    let mut option_key = linked_table.front();

    while (option_key.is_some()) {
        let key = *option_key.borrow();
        option_key = linked_table.next(key);
        keys.push_back(key);
    };

    keys
}

public fun linked_table_limit_keys<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
    offset: u64,
    limit: u64,
): (vector<K>, u64) {
    let total = linked_table.length();
    let mut keys = vector::empty<K>();

    if (offset < total && limit > 0) {
        let mut option_key = &option::some(linked_table_key_of(linked_table, offset));

        while (option_key.is_some() && keys.length() < limit) {
            let key = *option_key.borrow();
            option_key = linked_table.next(key);
            keys.push_back(key);
        };
    };

    (keys, total)
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
