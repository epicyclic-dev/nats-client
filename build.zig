// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");
const nats_build = @import("./nats-c.build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const nats = b.addModule("nats", .{
        .source_file = .{ .path = "src/nats.zig" },
    });

    const nats_c = nats_build.nats_c_lib(
        b,
        .{ .name = "nats-c", .target = target, .optimize = optimize },
    );

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    tests.addModule("nats", nats);
    tests.linkLibrary(nats_c);

    b.installArtifact(tests);
    const run_main_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_main_tests.step);
}
