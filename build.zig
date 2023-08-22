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

    const nats_c = nats_build.nats_c_lib(b, .{
        .name = "nats-c",
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "tests/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    tests.addModule("nats", nats);
    tests.linkLibrary(nats_c);

    const run_main_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_main_tests.step);

    add_examples(b, .{
        .target = target,
        .optimize = optimize,
        .nats_module = nats,
        .nats_c = nats_c,
    });
}

const ExampleOptions = struct {
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    nats_module: *std.Build.Module,
    nats_c: *std.Build.Step.Compile,
};

const Example = struct {
    name: []const u8,
    file: []const u8,
};

const examples = [_]Example{
    .{ .name = "request_reply", .file = "examples/request_reply.zig" },
};

pub fn add_examples(b: *std.build, options: ExampleOptions) void {
    const example_step = b.step("examples", "build examples");

    inline for (examples) |example| {
        const ex_exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = .{ .path = example.file },
            .target = options.target,
            .optimize = options.optimize,
        });

        ex_exe.addModule("nats", options.nats_module);
        ex_exe.linkLibrary(options.nats_c);

        const install = b.addInstallArtifact(ex_exe, .{});
        example_step.dependOn(&install.step);
    }
}
