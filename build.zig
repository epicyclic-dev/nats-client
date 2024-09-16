// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_libsodium = b.option(bool, "enable-libsodium", "Build with libsodium for higher-performance signing (default: true)") orelse true;
    const enable_tls = b.option(bool, "enable-tls", "Build TLS support (default: true)") orelse true;
    const tls_verify = b.option(bool, "force-host-verify", "Force hostname verification for TLS connections (default: true)") orelse true;
    const enable_streaming = b.option(bool, "enable-streaming", "Build with streaming support (default: true)") orelse true;

    const nats = b.addModule("nats", .{
        .root_source_file = b.path("src/nats.zig"),
    });

    const nats_c = b.dependency("nats_c", .{
        .target = target,
        .optimize = optimize,
        .@"enable-libsodium" = enable_libsodium,
        .@"enable-tls" = enable_tls,
        .@"force-host-verify" = tls_verify,
        .@"enable-streaming" = enable_streaming,
    });
    nats.linkLibrary(nats_c.artifact("nats"));

    const tests = b.addTest(.{
        .name = "nats-zig-unit-tests",
        .root_source_file = b.path("tests/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    tests.root_module.addImport("nats", nats);
    tests.linkLibrary(nats_c.artifact("nats"));

    const run_main_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addInstallArtifact(tests, .{}).step);
    test_step.dependOn(&run_main_tests.step);

    add_examples(b, .{
        .target = target,
        .optimize = optimize,
        .nats_module = nats,
    });
}

const ExampleOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    nats_module: *std.Build.Module,
};

const Example = struct {
    name: []const u8,
    file: []const u8,
};

const examples = [_]Example{
    .{ .name = "request_reply", .file = "examples/request_reply.zig" },
    .{ .name = "headers", .file = "examples/headers.zig" },
    .{ .name = "pub_bytes", .file = "examples/pub_bytes.zig" },
};

pub fn add_examples(b: *std.Build, options: ExampleOptions) void {
    const example_step = b.step("examples", "build examples");

    inline for (examples) |example| {
        const ex_exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(example.file),
            .target = options.target,
            .optimize = .Debug,
        });

        ex_exe.root_module.addImport("nats", options.nats_module);

        const install = b.addInstallArtifact(ex_exe, .{});
        example_step.dependOn(&install.step);
    }
}
