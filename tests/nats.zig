// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const nats = @import("nats");

test "version" {
    const version = nats.getVersion();
    const vernum = nats.getVersionNumber();

    try std.testing.expectEqualStrings("3.7.0", version);
    try std.testing.expectEqual(@as(u32, 0x03_07_00), vernum);
    try std.testing.expect(nats.checkCompatibility());
}

test "time" {
    const now = nats.now();
    const nownano = nats.nowInNanoseconds();

    nats.sleep(1);

    const later = nats.now();
    const laternano = nats.nowInNanoseconds();

    try std.testing.expect(later >= now);
    try std.testing.expect(laternano >= nownano);
}

test "init" {
    {
        try nats.init(nats.default_spin_count);
        defer nats.deinit();
    }

    {
        // a completely random number
        try nats.init(900_142_069);
        nats.deinit();
    }

    {
        try nats.init(0);
        try nats.deinitWait(1000);
    }
}

test "misc" {
    {
        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        try nats.setMessageDeliveryPoolSize(500);
    }

    {
        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        // just test that the function is wrapped properly
        nats.releaseThreadMemory();
    }

    blk: {
        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        // this is a mess of a test that is designed to fail because actually we're
        // testing out the error reporting functions instead of signing. Nice bait
        // and switch.
        const signed = nats.sign("12345678", "12345678") catch {
            const err = nats.getLastError();
            std.debug.print("as expected, signing failed: {s}\n", .{err.desc});

            var stackmem = [_]u8{0} ** 512;
            var stackbuf: []u8 = &stackmem;

            nats.getLastErrorStack(&stackbuf) catch {
                std.debug.print("Actually, the error stack was too big\n", .{});
                break :blk;
            };

            std.debug.print("stack: {s}\n", .{stackbuf});
            break :blk;
        };

        std.heap.raw_c_allocator.free(signed);
    }
}

test "inbox" {
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const inbox = try nats.createInbox();
    defer nats.destroyInbox(inbox);

    std.debug.print("inbox: {s}\n", .{inbox});
}
