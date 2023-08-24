const std = @import("std");

const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

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
