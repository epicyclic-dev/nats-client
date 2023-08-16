const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const err_ = @import("./error.zig");
const Error = err_.Error;
const Status = err_.Status;

pub const Message = opaque {
    pub fn create(subject: [:0]const u8, reply: ?[:0]const u8, data: ?[]const u8) Error!*Message {
        var self: *Message = undefined;
        const status = Status.fromInt(nats_c.natsMsg_Create(
            @ptrCast(&self),
            subject.ptr,
            if (reply) |r| r.ptr else null,
            if (data) |d| d.ptr else null,
            if (data) |d| @intCast(d.len) else 0,
        ));

        return status.toError() orelse self;
    }

    pub fn destroy(self: *Message) void {
        nats_c.natsMsg_Destroy(@ptrCast(self));
    }

    pub fn getSubject(self: *Message) [:0]const u8 {
        const subject = nats_c.natsMsg_GetSubject(@ptrCast(self)) orelse unreachable;
        return std.mem.sliceTo(subject, 0);
    }

    pub fn getReply(self: *Message) ?[:0]const u8 {
        const reply = nats_c.natsMsg_GetReply(@ptrCast(self)) orelse return null;
        return std.mem.sliceTo(reply, 0);
    }

    pub fn getData(self: *Message) ?[:0]const u8 {
        const data = nats_c.natsMsg_GetData(@ptrCast(self)) orelse return null;
        return data[0..self.getDataLength() :0];
    }

    pub fn getDataLength(self: *Message) usize {
        return @intCast(nats_c.natsMsg_GetDataLength(@ptrCast(self)));
    }

    pub fn setHeaderValue(self: *Message, key: [:0]const u8, value: ?[:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Set(@ptrCast(self), key.ptr, value.ptr));
        return status.raise();
    }

    pub fn addHeaderValue(self: *Message, key: [:0]const u8, value: ?[:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Add(@ptrCast(self), key.ptr, value.ptr));
        return status.raise();
    }

    pub fn getHeaderValue(self: *Message, key: [:0]const u8) Error!?[:0]const u8 {
        var value: ?[*]u8 = null;
        const status = Status.fromInt(nats_c.natsMsgHeader_Get(@ptrCast(self), key.ptr, &value));

        return status.toError() orelse if (value) |val| std.mem.sliceTo(u8, val, 0) else null;
    }

    pub fn getAllHeaderValues(self: *Message, key: [:0]const u8) Error![]?[*]const u8 {
        var values: [*]?[*]const u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(nats_c.natsMsgHeader_Values(@ptrCast(self), key.ptr, &values, &count));

        // the user must use std.mem.spanTo on each item they want to read to get a
        // slice, since we can't do that automatically without having to allocate.
        return status.toError() orelse values[0..@intCast(count)];
    }

    pub fn getAllHeaderKeys(self: *Message) Error![][*]const u8 {
        var keys: [*][*]const u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(nats_c.natsMsgHeader_Keys(@ptrCast(self), &keys, &count));

        // TODO: manually assert no keys are NULL?

        // the user must use std.mem.spanTo on each item they want to read to get a
        // slice, since we can't do that automatically without having to allocate.
        return status.toError() orelse keys[0..@intCast(count)];
    }

    pub fn deleteHeader(self: *Message, key: [:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Delete(@ptrCast(self), key.ptr));
        return status.raise();
    }

    pub fn isNoResponders(self: *Message) bool {
        return nats_c.natsMsg_IsNoResponders(@ptrCast(self));
    }
};

// TODO: not implementing jetstream API right now
// NATS_EXTERN natsStatus natsMsg_Ack(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_AckSync(natsMsg *msg, jsOptions *opts, jsErrCode *errCode);
// NATS_EXTERN natsStatus natsMsg_Nak(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_NakWithDelay(natsMsg *msg, int64_t delay, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_InProgress(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_Term(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN uint64_t natsMsg_GetSequence(natsMsg *msg);
// NATS_EXTERN int64_t natsMsg_GetTime(natsMsg *msg);

// TODO: not implementing streaming API right now
// NATS_EXTERN uint64_t stanMsg_GetSequence(const stanMsg *msg);
// NATS_EXTERN int64_t stanMsg_GetTimestamp(const stanMsg *msg);
// NATS_EXTERN bool stanMsg_IsRedelivered(const stanMsg *msg);
// NATS_EXTERN const char* stanMsg_GetData(const stanMsg *msg);
// NATS_EXTERN int stanMsg_GetDataLength(const stanMsg *msg);
// NATS_EXTERN void stanMsg_Destroy(stanMsg *msg);

test "message: create message" {
    const subject = "hello";
    const reply = "reply";
    const data = "world";

    const nats = @import("./nats.zig");

    // have to initialize the library so the reference counter can correctly destroy
    // objects, otherwise we segfault on trying to free the memory.
    try nats.init(-1);
    defer nats.deinit();

    const message = try Message.create(subject, reply, data);
    defer message.destroy();

    const message2 = try Message.create(subject, null, data);
    defer message2.destroy();

    const message3 = try Message.create(subject, data, null);
    defer message3.destroy();

    const message4 = try Message.create(subject, null, null);
    defer message4.destroy();
}

test "message: get subject" {
    const nats = @import("./nats.zig");

    try nats.init(-1);
    defer nats.deinit();

    const subject = "hello";
    const message = try Message.create(subject, null, null);
    defer message.destroy();

    const received = message.getSubject();
    try std.testing.expectEqualStrings(subject, received);
}

test "message: get reply" {
    const nats = @import("./nats.zig");

    try nats.init(-1);
    defer nats.deinit();

    const subject = "hello";
    const reply = "reply";
    const message = try Message.create(subject, reply, null);
    defer message.destroy();

    const received = message.getReply() orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings(reply, received);

    const message2 = try Message.create(subject, null, null);
    defer message2.destroy();

    const received2 = message2.getReply();
    try std.testing.expect(received2 == null);
}
