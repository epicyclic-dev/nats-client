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

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const err_ = @import("./error.zig");
const con_ = @import("./connection.zig");
const sub_ = @import("./subscription.zig");
const msg_ = @import("./message.zig");
const sta_ = @import("./statistics.zig");

pub const default_server_url = con_.default_server_url;
pub const Connection = con_.Connection;
pub const ConnectionOptions = con_.ConnectionOptions;

pub const Subscription = sub_.Subscription;

pub const Message = msg_.Message;

pub const Statistics = sta_.Statistics;
pub const StatsCounts = sta_.StatsCounts;

const Status = err_.Status;
pub const Error = err_.Error;

pub fn getVersion() [:0]const u8 {
    const verString = nats_c.nats_GetVersion();
    return std.mem.sliceTo(verString, 0);
}

pub fn getVersionNumber() u32 {
    return nats_c.nats_GetVersionNumber();
}

pub fn checkCompatibility() bool {
    return nats_c.nats_CheckCompatibilityImpl(
        nats_c.NATS_VERSION_REQUIRED_NUMBER,
        nats_c.NATS_VERSION_NUMBER,
        nats_c.NATS_VERSION_STRING,
    );
}

pub fn now() i64 {
    return nats_c.nats_Now();
}

pub fn nowInNanoSeconds() i64 {
    return nats_c.nats_NowInNanoSeconds();
}

pub fn sleep(sleep_time: i64) void {
    return nats_c.nats_Sleep(sleep_time);
}

pub fn setMessageDeliveryPoolSize(max: c_int) Error!void {
    const status = Status.fromInt(nats_c.nats_SetMessageDeliveryPoolSize(max));
    return status.raise();
}

pub fn releaseThreadMemory() void {
    return nats_c.nats_ReleaseThreadMemory();
}

pub fn init(lock_spin_count: i64) Error!void {
    const status = Status.fromInt(nats_c.nats_Open(lock_spin_count));
    return status.raise();
}

pub fn deinit() void {
    return nats_c.nats_Close();
}

// the result of this requires manual deallocation unless it is used to provide the
// signature out-parameter in the natsSignatureHandler callback. Calling it outside of
// that context seems unlikely, but we should probably provide a deinit function so the
// user doesn't have to dig around for libc free to deallocate it.
pub fn sign(encoded_seed: [:0]const u8, input: [:0]const u8) Error![]const u8 {
    var result: [*]u8 = undefined;
    var length: c_int = 0;
    const status = Status.fromInt(nats_c.nats_Sign(encoded_seed.ptr, &input, &length));

    return status.toError() orelse result[0..@intCast(length)];
}

pub fn deinitWait(timeout: i64) Error!void {
    const status = Status.fromInt(nats_c.nats_CloseAndWait(timeout));
    return status.raise();
}

// This appears to be a jetstream API, but these two endpoints are trivial, so, whoops.
// I have no clue what this does, since there's basically no
pub const Inbox = opaque {
    pub fn create() Error!*Inbox {
        var self: *Inbox = undefined;
        const status = Status.fromInt(nats_c.natsInbox_Create(@ptrCast(&self)));

        return status.toError() orelse self;
    }

    pub fn destroy(self: *Inbox) void {
        nats_c.natsInbox_Destroy(@ptrCast(self));
    }
};

// I think this is also a jetstream API. This function sure does not seem at all useful
// by itself.
pub const MessageList = opaque {
    pub fn destroy(self: *MessageList) void {
        nats_c.natsMsgList_Destroy(@ptrCast(self));
    }
};
