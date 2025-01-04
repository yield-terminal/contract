#[test_only]
module terminal::utils_tests;

use sui::linked_table::LinkedTable;
use terminal::utils;

#[test]
fun linked_table_keys_test() {
    let table = init_linked_table_test();

    assert!(utils::linked_table_keys(&table) ==  vector[1, 2, 3]);

    table.drop();
}

#[test]
fun linked_table_key_of_test() {
    let table = init_linked_table_test();

    assert!(utils::linked_table_key_of(&table, option::some(0)).extract() == 1);
    assert!(utils::linked_table_key_of(&table, option::some(1)).extract() == 2);
    assert!(utils::linked_table_key_of(&table, option::some(2)).extract() == 3);

    table.drop();
}

#[test]
fun linked_table_limit_keys_test() {
    let table = init_linked_table_test();

    let (keys, total)= utils::linked_table_limit_keys(&table, option::some(1), option::some(1));

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


