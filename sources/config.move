/// Module: Config
module terminal::config;

public struct RootCap has key {
    id: UID,
}

public struct AdminCap has key {
    id: UID,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(
        RootCap { id: object::new(ctx) },
        ctx.sender(),
    );
    transfer::transfer(
        AdminCap { id: object::new(ctx) },
        ctx.sender(),
    );
}

entry fun transfer_admin(_rootCap: &RootCap, adminCap: AdminCap, recipient: address) {
    transfer::transfer(
        adminCap,
        recipient,
    );
}
