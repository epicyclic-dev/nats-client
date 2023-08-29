const std = @import("std");

const nats = @import("nats");

const util = @import("./util.zig");

test "nats.Connection.connectTo" {
    {
        var server = try util.TestServer.launch(.{});
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo(nats.default_server_url);
        defer connection.destroy();
    }

    {
        var server = try util.TestServer.launch(.{
            .auth = .{ .token = "test_token" },
        });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo("nats://test_token@127.0.0.1:4222");
        defer connection.destroy();
    }

    {
        var server = try util.TestServer.launch(.{ .auth = .{
            .password = .{ .user = "user", .pass = "password" },
        } });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo("nats://user:password@127.0.0.1:4222");
        defer connection.destroy();
    }
}
