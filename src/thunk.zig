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

pub fn CallbackType(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .optional => |info| ?CallbackType(info.child),
        .pointer => |info| switch (info.size) {
            .Slice => *const T,
            else => T,
        },
        else => *T,
    };
}

pub const checkUserDataType = if (@hasField(std.builtin.Type, "optional"))
    checkUserDataType_14
else
    checkUserDataType_13;

pub fn checkUserDataType_14(comptime T: type) void {
    switch (@typeInfo(T)) {
        .optional => |info| switch (@typeInfo(info.child)) {
            .optional => @compileError(
                "nats callbacks can only accept an (optional) single, many," ++
                    " or c pointer as userdata. \"" ++
                    @typeName(T) ++ "\" has more than one optional specifier.",
            ),
            else => checkUserDataType(info.child),
        },
        .pointer => |info| switch (info.size) {
            .Slice => @compileError(
                "nats callbacks can only accept an (optional) single, many," ++
                    " or c pointer as userdata, not slices. \"" ++
                    @typeName(T) ++ "\" appears to be a slice.",
            ),
            else => {},
        },
        else => @compileError(
            "nats callbacks can only accept an (optional) single, many," ++
                " or c pointer as userdata. \"" ++
                @typeName(T) ++ "\" is not a pointer type.",
        ),
    }
}

pub fn checkUserDataType_13(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Optional => |info| switch (@typeInfo(info.child)) {
            .Optional => @compileError(
                "nats callbacks can only accept an (optional) single, many," ++
                    " or c pointer as userdata. \"" ++
                    @typeName(T) ++ "\" has more than one optional specifier.",
            ),
            else => checkUserDataType(info.child),
        },
        .Pointer => |info| switch (info.size) {
            .Slice => @compileError(
                "nats callbacks can only accept an (optional) single, many," ++
                    " or c pointer as userdata, not slices. \"" ++
                    @typeName(T) ++ "\" appears to be a slice.",
            ),
            else => {},
        },
        else => @compileError(
            "nats callbacks can only accept an (optional) single, many," ++
                " or c pointer as userdata. \"" ++
                @typeName(T) ++ "\" is not a pointer type.",
        ),
    }
}

const SimpleCallback = fn (?*anyopaque) callconv(.C) void;

pub fn SimpleCallbackThunkSignature(comptime T: type) type {
    return fn (T) void;
}

pub fn makeSimpleCallbackThunk(
    comptime T: type,
    comptime callback: *const SimpleCallbackThunkSignature(T),
) *const SimpleCallback {
    comptime checkUserDataType(T);
    return struct {
        fn thunk(userdata: ?*anyopaque) callconv(.C) void {
            const data: T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            callback(data);
        }
    }.thunk;
}
