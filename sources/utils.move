/// Module: Utils
module terminal::utils;

use sui::linked_table::LinkedTable;

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
    limit: Option<u64>,
    offset: Option<u64>,
): (vector<K>, u64) {
    let total = linked_table.length();
    let mut keys = vector::empty<K>();

    let limit_value = if (limit.is_none()) { *limit.borrow() } else { total };

    let mut option_key = &linked_table_key_of(linked_table, offset);

    while (option_key.is_some() && keys.length() < limit_value) {
        let key = *option_key.borrow();
        option_key = linked_table.next(key);
        keys.push_back(key);
    };

    (keys, total)
}

public fun linked_table_key_of<K: copy + drop + store, V: store>(
    linked_table: &LinkedTable<K, V>,
    offset: Option<u64>,
): Option<K> {
    let index = if (offset.is_none()) { *offset.borrow() } else { 0 };
    let total = linked_table.length();

    if (index >= total) return option::none<K>();
    if (index == total - 1) return *linked_table.back();

    let mut i = 0;
    let mut option_key = linked_table.front();
    while (i != index) {
        option_key = linked_table.next(*option_key.borrow());
        i = i + 1;
    };

    *option_key
}
