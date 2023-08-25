const std = @import("std");
const nats = @import("nats");

fn onMessage(
    userdata: *u32,
    connection: *nats.Connection,
    subscription: *nats.Subscription,
    message: *nats.Message,
) void {
    _ = subscription;

    std.debug.print("Subject \"{s}\" received message: \"{s}\"\n", .{
        message.getSubject(),
        message.getData() orelse "[null]",
    });

    if (message.getReply()) |reply| {
        connection.publish(reply, "salutations") catch @panic("HELP");
    }

    userdata.* += 1;
}

pub fn main() !void {
    const connection = try nats.Connection.connectTo(nats.default_server_url);
    defer connection.destroy();

    var count: u32 = 0;
    const subscription = try connection.subscribe(u32, "channel", onMessage, &count);
    defer subscription.destroy();

    while (count < 10) : (nats.sleep(1000)) {
        const reply = try connection.request("channel", "greetings", 1000);
        defer reply.destroy();

        std.debug.print("Reply \"{s}\" got message: {s}\n", .{
            reply.getSubject(),
            reply.getData() orelse "[null]",
        });
    }

    const stats = try connection.getStats();
    std.debug.print(
        "Server stats => {{\n\tmessages_in: {d} ({d} B),\n\tmessages_out: {d} ({d} B),\n\treconnects: {d}\n}}\n",
        .{ stats.messages_in, stats.bytes_in, stats.messages_out, stats.bytes_out, stats.reconnects },
    );
}
