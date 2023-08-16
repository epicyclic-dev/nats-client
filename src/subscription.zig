const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const Connection = @import("./connection.zig").Connection;
const Message = @import("./message.zig").Message;
const err_ = @import("./error.zig");
const Error = err_.Error;
const Status = err_.Status;

pub const MessageCount = struct {
    messages: c_int = 0,
    bytes: c_int = 0,
};

pub const SubscriptionStats = struct {
    pending: MessageCount = .{},
    max_pending: MessageCount = .{},
    delivered_messages: i64 = 0,
    dropped_messages: i64 = 0,
};

pub const Subscription = opaque {
    pub fn isValid(self: *Subscription) bool {
        return nats_c.natsSubscription_IsValid(@ptrCast(self));
    }

    pub fn destroy(self: *Subscription) void {
        nats_c.natsSubscription_Destroy(@ptrCast(self));
    }

    pub fn unsubscribe(self: *Subscription) Error!void {
        return Status.fromInt(nats_c.natsSubscription_Unsubscribe(@ptrCast(self))).raise();
    }

    pub fn autoUnsubscribe(self: *Subscription, max: c_int) Error!void {
        return Status.fromInt(nats_c.natsSubscription_AutoUnsubscribe(@ptrCast(self), max)).raise();
    }

    pub fn nextMessage(self: *Subscription, timeout: i64) Error!*Message {
        var message: *Message = undefined;
        const status = Status.fromInt(nats_c.natsSubscription_NextMsg(
            @ptrCast(&message),
            @ptrCast(self),
            timeout,
        ));

        return status.toError() orelse message;
    }

    pub fn queuedMessageCount(self: *Subscription) Error!u64 {
        var count: u64 = 0;
        const status = Status.fromInt(nats_c.natsSubscription_QueuedMsgs(@ptrCast(self), &count));
        return status.toError() orelse count;
    }

    pub fn getId(self: *Subscription) i64 {
        // TODO: invalid/closed subscriptions return 0. Should we convert that into an
        // error? could return error.InvalidSubscription
        return nats_c.natsSubscription_GetID(@ptrCast(self));
    }

    pub fn getSubject(self: *Subscription) ?[:0]const u8 {
        // invalid/closed subscriptions return null. should we convert that into an
        // error? could return error.InvalidSubscription
        const result = nats_c.natsSubscription_GetSubject(@ptrCast(self)) orelse return null;
        return std.mem.spanTo(u8, result, 0);
    }

    pub fn setPendingLimits(self: *Subscription, limit: MessageCount) Error!void {
        return Status.fromInt(
            nats_c.natsSubscription_SetPendingLimits(@ptrCast(self), limit.messages, limit.bytes),
        ).raise();
    }

    pub fn getPendingLimits(self: *Subscription) Error!MessageCount {
        var result: MessageCount = .{};
        const status = Status.fromInt(
            nats_c.natsSubscription_GetPendingLimits(@ptrCast(self), &result.messages, &result.bytes),
        );

        return status.toError() orelse result;
    }

    pub fn getPending(self: *Subscription) Error!MessageCount {
        var result: MessageCount = .{};
        const status = Status.fromInt(
            nats_c.natsSubscription_GetPending(@ptrCast(self), &result.messages, &result.bytes),
        );

        return status.toError() orelse result;
    }

    pub fn getMaxPending(self: *Subscription) Error!MessageCount {
        var result: MessageCount = .{};
        const status = Status.fromInt(
            nats_c.natsSubscription_GetMaxPending(@ptrCast(self), &result.messages, &result.bytes),
        );

        return status.toError() orelse result;
    }

    pub fn clearMaxPending(self: *Subscription) Error!void {
        return Status.fromInt(nats_c.natsSubscription_ClearMaxPending(@ptrCast(self))).raise();
    }

    pub fn getDelivered(self: *Subscription) Error!i64 {
        var result: i64 = 0;
        const status = Status.fromInt(nats_c.natsSubscription_GetDelivered(@ptrCast(self), &result));

        return status.toError() orelse result;
    }

    pub fn getDropped(self: *Subscription) Error!i64 {
        var result: i64 = 0;
        const status = Status.fromInt(nats_c.natsSubscription_GetDropped(@ptrCast(self), &result));

        return status.toError() orelse result;
    }

    pub fn getStats(self: *Subscription) Error!SubscriptionStats {
        var result: SubscriptionStats = .{};
        const status = Status.fromInt(nats_c.natsSubscription_GetStats(
            @ptrCast(self),
            &result.pending.messages,
            &result.pending.bytes,
            &result.max_pending.messages,
            &result.max_pending.bytes,
            &result.delivered_messages,
            &result.dropped_messages,
        ));

        return status.toError() orelse result;
    }

    pub fn drain(self: *Subscription) Error!void {
        return Status.fromInt(nats_c.natsSubscription_Drain(@ptrCast(self))).raise();
    }

    pub fn drainTimeout(self: *Subscription, timeout: i64) Error!void {
        return Status.fromInt(nats_c.natsSubscription_DrainTimeout(@ptrCast(self), timeout)).raise();
    }

    pub fn waitForDrainCompletion(self: *Subscription, timeout: i64) Error!void {
        return Status.fromInt(nats_c.natsSubscription_WaitForDrainCompletion(@ptrCast(self), timeout)).raise();
    }

    pub fn drainCompletionStatus(self: *Subscription) ?Error {
        return Status.fromInt(nats_c.natsSubscription_DrainCompletionStatus(@ptrCast(self))).toError();
    }

    pub fn setCompletionCallback(
        self: *Subscription,
        comptime T: type,
        comptime callback: *const CompletionThunkCallback(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsSubscription_SetOnCompleteCB(
            @ptrCast(self),
            completionCallbackThunk(callback),
            userdata,
        )).raise();
    }
};

const BareSubscriptionCallback = fn (
    ?*nats_c.natsConnection,
    ?*nats_c.natsSubscription,
    ?*nats_c.natsMsg,
    ?*anyopaque,
) callconv(.C) void;

pub fn SubscriptionThunkCallback(comptime T: type) type {
    return fn (*T, *Connection, *Subscription, *Message) void;
}

pub fn subscriptionMessageThunk(
    comptime T: type,
    comptime callback: *const SubscriptionThunkCallback(T),
) *const BareSubscriptionCallback {
    return struct {
        fn thunk(
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

const BareCompletionCallback = fn (?*anyopaque) callconv(.C) void;
pub fn CompletionThunkCallback(comptime T: type) type {
    return fn (*T) void;
}

pub fn completionCallbackThunk(
    comptime T: type,
    comptime callback: *const CompletionThunkCallback(T),
) *const BareSubscriptionCallback {
    return struct {
        fn thunk(userdata: ?*anyopaque) callconv(.C) void {
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;
            callback(data);
        }
    }.thunk;
}
