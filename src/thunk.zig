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

const optional = if (@hasField(std.builtin.Type, "optional")) .optional else .Optional;
const pointer = if (@hasField(std.builtin.Type, "pointer")) .pointer else .Pointer;
const void_type = if (@hasField(std.builtin.Type, "void")) .void else .Void;
const null_type = if (@hasField(std.builtin.Type, "null")) .null else .Null;

pub fn opaqueFromUserdata(userdata: anytype) ?*anyopaque {
    checkUserDataType(@TypeOf(userdata));
    return switch (@typeInfo(@TypeOf(userdata))) {
        optional, pointer => @constCast(@ptrCast(userdata)),
        void_type => null,
        else => @compileError("Unsupported userdata type " ++ @typeName(@TypeOf(userdata))),
    };
}

pub fn userdataFromOpaque(comptime UDT: type, userdata: ?*anyopaque) UDT {
    comptime checkUserDataType(UDT);
    return if (UDT == void)
        void{}
    else if (@typeInfo(UDT) == optional)
        @alignCast(@ptrCast(userdata))
    else
        @alignCast(@ptrCast(userdata.?));
}

pub fn checkUserDataType(comptime T: type) void {
    switch (@typeInfo(T)) {
        optional => |info| switch (@typeInfo(info.child)) {
            optional => @compileError(
                "nats callbacks can only accept void or an (optional) single, many," ++
                    " or c pointer as userdata. \"" ++
                    @typeName(T) ++ "\" has more than one optional specifier.",
            ),
            else => checkUserDataType(info.child),
        },
        pointer => |info| switch (info.size) {
            .Slice => @compileError(
                "nats callbacks can only accept void or an (optional) single, many," ++
                    " or c pointer as userdata, not slices. \"" ++
                    @typeName(T) ++ "\" appears to be a slice.",
            ),
            else => {},
        },
        void_type => {},
        else => @compileError(
            "nats callbacks can only accept void or an (optional) single, many," ++
                " or c pointer as userdata. \"" ++
                @typeName(T) ++ "\" is not a pointer type.",
        ),
    }
}

const SimpleCallback = fn (?*anyopaque) callconv(.C) void;

pub fn SimpleCallbackThunkSignature(comptime UDT: type) type {
    return fn (UDT) void;
}

pub fn makeSimpleCallbackThunk(
    comptime UDT: type,
    comptime callback: *const SimpleCallbackThunkSignature(UDT),
) *const SimpleCallback {
    comptime checkUserDataType(UDT);
    return struct {
        fn thunk(userdata: ?*anyopaque) callconv(.C) void {
            callback(userdataFromOpaque(UDT, userdata));
        }
    }.thunk;
}
