// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const nats = @import("nats");

test "message: create message" {
    const subject = "hello";
    const reply = "reply";
    const data = "world";

    // have to initialize the library so the reference counter can correctly destroy
    // objects, otherwise we segfault on trying to free the memory.
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const message = try nats.Message.create(subject, reply, data);
    defer message.destroy();

    const message2 = try nats.Message.create(subject, null, data);
    defer message2.destroy();

    const message3 = try nats.Message.create(subject, data, null);
    defer message3.destroy();

    const message4 = try nats.Message.create(subject, null, null);
    defer message4.destroy();
}

test "message: get subject" {
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const subject = "hello";
    const message = try nats.Message.create(subject, null, null);
    defer message.destroy();

    const received = message.getSubject();
    try std.testing.expectEqualStrings(subject, received);
}

test "message: get reply" {
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const subject = "hello";
    const reply = "reply";
    const message = try nats.Message.create(subject, reply, null);
    defer message.destroy();

    const received = message.getReply() orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings(reply, received);

    const message2 = try nats.Message.create(subject, null, null);
    defer message2.destroy();

    const received2 = message2.getReply();
    try std.testing.expect(received2 == null);
}
