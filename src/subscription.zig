const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const Connection = @import("./connection.zig").Connection;
const Message = @import("./message.zig").Message;
const err_ = @import("./error.zig");
const Error = err_.Error;
const Status = err_.Status;

const SubCallback = fn (?*nats_c.natsConnection, ?*nats_c.natsSubscription, ?*nats_c.natsMsg, ?*anyopaque) callconv(.C) void;
pub fn ThunkCallback(comptime T: type) type {
    return fn (*T, *Connection, *Subscription, *Message) void;
}

pub fn messageThunk(comptime T: type, comptime callback: *const ThunkCallback(T)) *const SubCallback {
    return struct {
        pub fn thunk(
            conn: ?*nats_c.natsConnection,
            sub: ?*nats_c.natsSubscription,
            msg: ?*nats_c.natsMsg,
            userdata: ?*anyopaque,
        ) callconv(.C) void {
            const message: *Message = if (msg) |m| @ptrCast(m) else unreachable;
            defer message.destroy();

            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const subscription: *Subscription = if (sub) |s| @ptrCast(s) else unreachable;

            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;

            callback(data, connection, subscription, message);
        }
    }.thunk;
}

pub const Subscription = opaque {
    pub fn destroy(self: *Subscription) void {
        nats_c.natsSubscription_Destroy(@ptrCast(self));
    }
};

// pub fn Subscription(T: type) type {
//     return struct {
//         const Self = @This();

//         _internal: *nats_c.natsSubscription,
//         userdata: T,
//         function: MessageCallback(T),

//         pub fn create(
//             allocator: std.mem.Allocator,
//             userdata: T,
//             callback: MessageCallback(T),
//         ) AllocError!*Self {
//             const self: *Self = try std.mem.Allocator.create(Self);
//             self.userdata = userdata;
//             self.function = callback;
//             return self;
//         }

//         pub fn wrap(
//             self: *Self,
//             internal: *nats_c.natsSubscription,
//         ) void {
//             // self._internal =
//         }

//         fn thunk(
//             conn: ?*nats_c.natsConnection,
//             sub: ?*nats_c.natsSubscription,
//             msg: ?*nats_c.natsMsg,
//             userdata: ?*const anyopaque,
//         ) callconv(.C) void {
//             self.function(self.userdata, connection, subscription, message);
//         }
//     };
// }

pub fn MessageCallback(comptime T: type) type {
    return *const fn (userdata: T, connection: *Connection, subscription: *Subscription, message: *Message) void;
}
