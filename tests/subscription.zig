// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const nats = @import("nats");

const util = @import("./util.zig");

test "nats.Subscription" {
    var server = try util.TestServer.launch(.{});
    defer server.stop();

    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const connection = try nats.Connection.connectTo(server.url);
    defer connection.destroy();

    const message_subject: [:0]const u8 = "hello";
    const message_reply: [:0]const u8 = "reply";
    const message_data: [:0]const u8 = "world";

    const message = try nats.Message.create(message_subject, message_reply, message_data);
    defer message.destroy();

    {
        const subscription = try connection.subscribeSync(message_subject);
        defer subscription.destroy();

        try subscription.autoUnsubscribe(1);
        try subscription.setPendingLimits(.{ .messages = 10, .bytes = 1000 });
        _ = try subscription.getPendingLimits();
        _ = try subscription.getPending();
        _ = try subscription.getMaxPending();
        try subscription.clearMaxPending();
        _ = try subscription.getDelivered();
        _ = try subscription.getDropped();
        _ = try subscription.getStats();
        _ = try subscription.queuedMessageCount();
        _ = subscription.getId();
        const subj = subscription.getSubject() orelse return error.TestUnexpectedResult;
        try std.testing.expectEqualStrings(message_subject, subj);

        try connection.publishMessage(message);
        const roundtrip = try subscription.nextMessage(1000);
        try std.testing.expectEqualStrings(
            message_data,
            roundtrip.getData() orelse return error.TestUnexpectedResult,
        );

        try std.testing.expect(subscription.isValid() == false);
    }

    {
        const subscription = try connection.queueSubscribeSync(message_subject, "queuegroup");
        defer subscription.destroy();

        try subscription.drain();
        try subscription.waitForDrainCompletion(1000);
        _ = subscription.drainCompletionStatus();
    }

    {
        const subscription = try connection.subscribeSync(message_subject);
        defer subscription.destroy();

        try subscription.drain();
        try subscription.waitForDrainCompletion(1000);
        _ = subscription.drainCompletionStatus();
    }

    {
        const subscription = try connection.subscribeSync(message_subject);
        defer subscription.destroy();

        try subscription.drainTimeout(1000);
        try subscription.waitForDrainCompletion(1000);
    }
}

fn onMessage(
    userdata: *const u32,
    connection: *nats.Connection,
    subscription: *nats.Subscription,
    message: *nats.Message,
) void {
    _ = subscription;
    _ = userdata;

    if (message.getReply()) |reply| {
        connection.publish(reply, "greetings") catch @panic("OH NO");
    } else @panic("HOW");
}

fn onClose(userdata: *[]const u8) void {
    userdata.* = "closed";
}

test "nats.Subscription (async)" {
    var server = try util.TestServer.launch(.{});
    defer server.stop();

    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const connection = try nats.Connection.connectTo(server.url);
    defer connection.destroy();

    const message_subject: [:0]const u8 = "hello";
    const message_reply: [:0]const u8 = "reply";
    const message_data: [:0]const u8 = "world";

    const message = try nats.Message.create(message_subject, message_reply, message_data);
    defer message.destroy();

    {
        var closed: []const u8 = "test";
        {
            const count: u32 = 0;
            const subscription = try connection.subscribe(*const u32, message_subject, onMessage, &count);
            defer subscription.destroy();

            try subscription.setCompletionCallback(*[]const u8, onClose, &closed);

            const response = try connection.requestMessage(message, 1000);
            try std.testing.expectEqualStrings(
                "greetings",
                response.getData() orelse return error.TestUnexpectedResult,
            );
        }
        // we have to sleep to allow the close callback to run. I am worried this may
        // still end up being flaky, however.
        nats.sleep(1);
        try std.testing.expectEqualStrings("closed", closed);
    }

    {
        const count: u32 = 0;
        const subscription = try connection.subscribeTimeout(
            *const u32,
            message_subject,
            1000,
            onMessage,
            &count,
        );
        defer subscription.destroy();

        const response = try connection.requestMessage(message, 1000);
        try std.testing.expectEqualStrings(
            "greetings",
            response.getData() orelse return error.TestUnexpectedResult,
        );
    }

    {
        const count: u32 = 0;
        const subscription = try connection.queueSubscribe(
            *const u32,
            message_subject,
            "queuegroup",
            onMessage,
            &count,
        );
        defer subscription.destroy();

        const response = try connection.requestMessage(message, 1000);
        try std.testing.expectEqualStrings(
            "greetings",
            response.getData() orelse return error.TestUnexpectedResult,
        );
    }

    {
        var count: u32 = 0;
        const subscription = try connection.queueSubscribeTimeout(
            *const u32,
            message_subject,
            "queuegroup",
            1000,
            onMessage,
            &count,
        );
        defer subscription.destroy();

        const response = try connection.requestMessage(message, 1000);
        try std.testing.expectEqualStrings(
            "greetings",
            response.getData() orelse return error.TestUnexpectedResult,
        );
    }
}
