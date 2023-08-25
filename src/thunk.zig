const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const SimpleCallback = fn (?*anyopaque) callconv(.C) void;

pub fn SimpleCallbackThunkSignature(comptime T: type) type {
    return fn (*T) void;
}

pub fn makeSimpleCallbackThunk(
    comptime T: type,
    comptime callback: *const SimpleCallbackThunkSignature(T),
) *const SimpleCallback {
    return struct {
        fn thunk(userdata: ?*anyopaque) callconv(.C) void {
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            callback(data);
        }
    }.thunk;
}
