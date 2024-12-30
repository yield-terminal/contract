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

    let limit_value = if (limit.is_some()) { *limit.borrow() } else { total };

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
    let total = linked_table.length();
    let index = if (offset.is_some()) { *offset.borrow() } else { 0 };

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


// Tests ------------------------------------------------------------------------------------------
#[test]
fun linked_table_keys_test() {
    let table = init_linked_table_test();

    assert!(linked_table_keys(&table) ==  vector[1, 2, 3]);

    table.drop();
}

#[test]
fun linked_table_key_of_test() {
    let table = init_linked_table_test();

    assert!(linked_table_key_of(&table, option::some(0)).extract() == 1);
    assert!(linked_table_key_of(&table, option::some(1)).extract() == 2);
    assert!(linked_table_key_of(&table, option::some(2)).extract() == 3);

    table.drop();
}

#[test]
fun linked_table_limit_keys_test() {
    let table = init_linked_table_test();

    let (keys, total)= linked_table_limit_keys(&table, option::some(1), option::some(1));

    assert!(keys == vector[2]);
    assert!(total == 3);

    table.drop();
}

#[test_only]
fun init_linked_table_test(): LinkedTable<u64, u8> {
    let ctx = &mut tx_context::dummy();
    let mut table = sui::linked_table::new<u64, u8>(ctx);

    table.push_back(1, 10);
    table.push_back(2, 20);
    table.push_back(3, 30);

    return table
}
