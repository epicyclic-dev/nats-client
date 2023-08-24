const std = @import("std");
const nats = @import("nats");

pub fn main() !void {
    const connection = try nats.Connection.connectTo(nats.default_server_url);
    defer connection.destroy();

    const message = try nats.Message.create("subject", null, "message");
    defer message.destroy();

    try message.setHeaderValue("My-Key1", "value1");
    try message.setHeaderValue("My-Key2", "value2");
    try message.addHeaderValue("My-Key1", "value3");
    try message.setHeaderValue("My-Key3", "value4");

    try message.deleteHeader("My-Key3");

    {
        var iter = try message.headerIterator();
        defer iter.destroy();

        while (iter.next()) |resolv| {
            var val_iter = try resolv.getValueIterator();
            defer val_iter.destroy();

            std.debug.print("key '{s}' got: ", .{resolv.key});
            while (val_iter.next()) |value| {
                std.debug.print("'{s}', ", .{value});
            }
            std.debug.print("\n", .{});
        }
    }

    const subscription = try connection.subscribeSync("subject");
    defer subscription.destroy();

    try connection.publishMessage(message);
    const received = try subscription.nextMessage(1000);
    defer received.destroy();

    {
        var iter = try received.getHeaderValueIterator("My-Key1");
        defer iter.destroy();

        std.debug.print("For key 'My-Key1' got: ", .{});
        while (iter.next()) |value| {
            std.debug.print("'{s}', ", .{value});
        }
        std.debug.print("\n", .{});
    }

    _ = received.getHeaderValue("key-does-not-exist") catch |err| switch (err) {
        nats.Error.NotFound => {},
        else => {
            std.debug.print("Should not have found that key!", .{});
            return err;
        },
    };

    received.deleteHeader("key-does-not-exist") catch |err| switch (err) {
        nats.Error.NotFound => {},
        else => {
            std.debug.print("Should not have found that key!", .{});
            return err;
        },
    };
}
