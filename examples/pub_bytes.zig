// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");
const nats = @import("nats");

pub fn main() !void {
    const connection = try nats.Connection.connectTo(nats.default_server_url);
    defer connection.destroy();

    const data = [_]u8{ 104, 101, 108, 108, 111, 33 };
    try connection.publish("subject", &data);
}
