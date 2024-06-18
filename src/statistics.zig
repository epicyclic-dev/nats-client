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
const Status = err_.Status;
const Error = err_.Error;

pub const StatsCounts = struct {
    messages_in: u64 = 0,
    bytes_in: u64 = 0,
    messages_out: u64 = 0,
    bytes_out: u64 = 0,
    reconnects: u64 = 0,
};

pub const Statistics = opaque {
    pub fn create() Error!*Statistics {
        var stats: *Statistics = undefined;
        const status = Status.fromInt(nats_c.natsStatistics_Create(@ptrCast(&stats)));
        return status.toError() orelse stats;
    }

    pub fn destroy(self: *Statistics) void {
        nats_c.natsStatistics_Destroy(@ptrCast(self));
    }

    pub fn getCounts(self: *Statistics) Error!StatsCounts {
        var counts: StatsCounts = .{};
        const status = Status.fromInt(nats_c.natsStatistics_GetCounts(
            @ptrCast(self),
            &counts.messages_in,
            &counts.bytes_in,
            &counts.messages_out,
            &counts.bytes_out,
            &counts.reconnects,
        ));
        return status.toError() orelse counts;
    }
};
