const std = @import("std");
const nats = @import("nats");

pub fn main() !void {
    const connection = try nats.Connection.connectTo(nats.default_server_url);
    defer connection.destroy();

    const data = [_]u8{ 104, 101, 108, 108, 111, 33 };
    try connection.publish("subject", &data);
}
