const std = @import("std");
const nats_build = @import("./nats-c.build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const nats = b.addModule("nats", .{
    //     .source_file = .{ .path = "source/nats.zig" },
    // });

    const nats = b.addExecutable(.{
        .name = "nats_test",
        .root_source_file = .{ .path = "src/nats.zig" },
        .target = target,
        .optimize = optimize,
    });

    const tinfo = nats.target_info.target;

    const nats_c = nats_build.nats_c_lib(
        b,
        .{ .name = "nats-c", .target = target, .optimize = optimize },
    );
    switch (tinfo.os.tag) {
        .windows => {
            if (tinfo.abi != .msvc) {
                nats_c.addCSourceFiles(&.{"src/win-crosshack.c"}, &.{"-fno-sanitize=undefined"});
            }
        },
        else => {},
    }

    nats.linkLibrary(nats_c);
    b.installArtifact(nats);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/nats.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_main_tests.step);
}
