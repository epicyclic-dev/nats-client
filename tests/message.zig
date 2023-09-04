// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const nats = @import("nats");

const util = @import("./util.zig");

test "nats.Message" {
    const message_subject: [:0]const u8 = "hello";
    const message_reply: [:0]const u8 = "reply";
    const message_data: [:0]const u8 = "world";

    // have to initialize the library so the reference counter can correctly destroy
    // objects, otherwise we segfault on trying to free the memory.
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    {
        const message = try nats.Message.create(message_subject, null, message_data);
        defer message.destroy();
    }

    {
        const message = try nats.Message.create(message_subject, message_reply, null);
        defer message.destroy();
    }

    {
        const message = try nats.Message.create(message_subject, null, null);
        defer message.destroy();
    }

    const message = try nats.Message.create(message_subject, message_reply, message_data);
    defer message.destroy();

    const subject = message.getSubject();
    try std.testing.expectEqualStrings(message_subject, subject);

    const reply = message.getReply() orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings(message_reply, reply);

    const data = message.getData() orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings(message_data, data);

    try std.testing.expectEqual(message_data.len, message.getDataLength());

    const message_header: [:0]const u8 = "foo";
    const message_hvalues: []const [:0]const u8 = &.{ "bar", "baz" };
    try message.setHeaderValue(message_header, message_hvalues[0]);

    try std.testing.expectEqualStrings(message_hvalues[0], try message.getHeaderValue(message_header));
    try message.addHeaderValue(message_header, message_hvalues[1]);
    try std.testing.expectEqualStrings(message_hvalues[0], try message.getHeaderValue(message_header));

    {
        var idx: usize = 0;
        var val_iter = try message.getHeaderValueIterator(message_header);
        defer val_iter.destroy();

        while (val_iter.next()) |value| : (idx += 1) {
            try std.testing.expect(idx < message_hvalues.len);
            try std.testing.expectEqualStrings(message_hvalues[idx], value);
        }
    }

    {
        var header_iter = try message.getHeaderIterator();
        defer header_iter.destroy();

        while (header_iter.next()) |header| {
            try std.testing.expectEqualStrings(message_header, header.key);
            try std.testing.expectEqualStrings(message_hvalues[0], try header.value());

            var idx: usize = 0;
            var val_iter = try header.valueIterator();
            defer val_iter.destroy();

            while (val_iter.next()) |value| : (idx += 1) {
                try std.testing.expect(idx < message_hvalues.len);
                try std.testing.expectEqualStrings(message_hvalues[idx], value);
            }

            try std.testing.expect(val_iter.peek() == null);
        }
        try std.testing.expect(header_iter.peek() == null);
    }

    try message.deleteHeader(message_header);
    _ = message.isNoResponders();
}

test "send nats.Message" {
    var server = try util.TestServer.launch(.{});
    defer server.stop();

    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const connection = try nats.Connection.connectTo(server.url);
    defer connection.destroy();

    const message_subject: [:0]const u8 = "hello";
    const message_reply: [:0]const u8 = "reply";
    const message_data: [:0]const u8 = "world";
    const message_header: [:0]const u8 = "foo";
    const message_hvalues: []const [:0]const u8 = &.{ "bar", "baz" };

    const message = try nats.Message.create(message_subject, message_reply, message_data);
    defer message.destroy();

    try message.setHeaderValue(message_header, message_hvalues[0]);
    try message.addHeaderValue(message_header, message_hvalues[1]);

    try connection.publishMessage(message);
}
