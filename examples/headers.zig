// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");
const nats = @import("nats");

pub fn main() !void {
    const connection = try nats.Connection.connectTo(nats.default_server_url);
    defer connection.destroy();

    const message = try nats.Message.create("subject", null, "message");
    defer message.destroy();

    try message.setHeaderValue("foo", "foo-value");
    try message.setHeaderValue("bar", "bar-value");
    try message.addHeaderValue("foo", "bar-value");
    try message.setHeaderValue("baz", "baz-value");
    try message.addHeaderValue("qux", "qux-value");

    try message.deleteHeader("baz");

    {
        var iter = try message.getHeaderIterator();
        defer iter.destroy();

        while (iter.next()) |header| {
            var val_iter = try header.valueIterator();
            defer val_iter.destroy();

            std.debug.print("key '{s}' got: ", .{header.key});
            while (val_iter.next()) |value| {
                std.debug.print("'{s}'{s}", .{ value, if (val_iter.peek()) |_| ", " else "" });
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
        var iter = try received.getHeaderValueIterator("foo");
        defer iter.destroy();

        std.debug.print("For key 'foo' got: ", .{});
        while (iter.next()) |value| {
            std.debug.print("'{s}'{s}", .{ value, if (iter.peek()) |_| ", " else "" });
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
