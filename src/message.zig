// Copyright 2023 torque@epicyclic.dev
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const std = @import("std");

const nats_c = @import("./nats_c.zig").nats_c;

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

    pub fn setHeaderValue(self: *Message, key: [:0]const u8, value: [:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Set(@ptrCast(self), key.ptr, value.ptr));
        return status.raise();
    }

    pub fn addHeaderValue(self: *Message, key: [:0]const u8, value: [:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Add(@ptrCast(self), key.ptr, value.ptr));
        return status.raise();
    }

    pub fn getHeaderValue(self: *Message, key: [:0]const u8) Error![:0]const u8 {
        var value: ?[*:0]u8 = null;
        const status = Status.fromInt(nats_c.natsMsgHeader_Get(@ptrCast(self), key.ptr, &value));

        return status.toError() orelse std.mem.sliceTo(value.?, 0);
    }

    pub fn getHeaderValueIterator(self: *Message, key: [:0]const u8) Error!HeaderValueIterator {
        return .{ .values = try self.getAllHeaderValues(key) };
    }

    pub fn getHeaderIterator(self: *Message) Error!HeaderIterator {
        return .{
            .message = self,
            .keys = try self.getAllHeaderKeys(),
        };
    }

    pub fn deleteHeader(self: *Message, key: [:0]const u8) Error!void {
        const status = Status.fromInt(nats_c.natsMsgHeader_Delete(@ptrCast(self), key.ptr));
        return status.raise();
    }

    pub fn isNoResponders(self: *Message) bool {
        return nats_c.natsMsg_IsNoResponders(@ptrCast(self));
    }

    // prefer using message.getHeaderValueIterator
    pub fn getAllHeaderValues(self: *Message, key: [:0]const u8) Error![][*:0]const u8 {
        var values: [*][*:0]const u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(
            nats_c.natsMsgHeader_Values(@ptrCast(self), key.ptr, @ptrCast(&values), &count),
        );

        // the user must use std.mem.spanTo on each item they want to read to get a
        // slice, since we can't do that automatically without having to allocate.
        return status.toError() orelse values[0..@intCast(count)];
    }

    // prefer using message.getHeaderIterator
    pub fn getAllHeaderKeys(self: *Message) Error![][*:0]const u8 {
        var keys: [*][*:0]const u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(nats_c.natsMsgHeader_Keys(@ptrCast(self), @ptrCast(&keys), &count));

        // the user must use std.mem.spanTo on each item they want to read to get a
        // slice, since we can't do that automatically without having to allocate.
        // the returned slice
        return status.toError() orelse keys[0..@intCast(count)];
    }

    pub const HeaderValueIterator = struct {
        values: [][*:0]const u8,
        index: usize = 0,

        pub fn destroy(self: HeaderValueIterator) void {
            std.heap.raw_c_allocator.free(self.values);
        }

        pub const deinit = HeaderValueIterator.destroy;

        pub fn next(self: *HeaderValueIterator) ?[:0]const u8 {
            if (self.index >= self.values.len) return null;
            defer self.index += 1;

            return std.mem.sliceTo(self.values[self.index], 0);
        }

        pub fn peek(self: *HeaderValueIterator) ?[:0]const u8 {
            if (self.index >= self.values.len) return null;
            return std.mem.sliceTo(self.values[self.index], 0);
        }
    };

    pub const HeaderIterator = struct {
        message: *Message,
        keys: [][*:0]const u8,
        index: usize = 0,

        pub const ValueResolver = struct {
            message: *Message,
            key: [:0]const u8,

            pub fn value(self: ValueResolver) Error![:0]const u8 {
                // TODO: if we didn't care about the lifecycle of self.message, we
                // could do catch unreachable here and make this error-free
                return try self.message.getHeaderValue(self.key);
            }

            pub fn valueIterator(self: ValueResolver) Error!HeaderValueIterator {
                return try self.message.getHeaderValueIterator(self.key);
            }
        };

        pub fn destroy(self: *HeaderIterator) void {
            std.heap.raw_c_allocator.free(self.keys);
        }

        pub const deinit = HeaderIterator.destroy;

        pub fn next(self: *HeaderIterator) ?ValueResolver {
            if (self.index >= self.keys.len) return null;
            defer self.index += 1;

            return .{
                .message = self.message,
                .key = std.mem.sliceTo(self.keys[self.index], 0),
            };
        }

        pub fn peek(self: *HeaderIterator) ?ValueResolver {
            if (self.index >= self.keys.len) return null;
            return .{
                .message = self.message,
                .key = std.mem.sliceTo(self.keys[self.index], 0),
            };
        }

        pub fn nextKey(self: *HeaderIterator) ?[:0]const u8 {
            if (self.index >= self.keys.len) return null;
            defer self.index += 1;
            return std.mem.sliceTo(self.keys[self.index], 0);
        }

        pub fn peekKey(self: *HeaderIterator) ?[:0]const u8 {
            if (self.index >= self.keys.len) return null;
            return std.mem.sliceTo(self.keys[self.index], 0);
        }
    };
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
