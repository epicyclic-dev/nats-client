// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const NatsCOptions = struct {
    name: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn nats_c_lib(
    b: *std.Build,
    options: NatsCOptions,
) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = options.name,
        .target = options.target,
        .optimize = options.optimize,
    });

    const cflags = [_][]const u8{
        "-fno-sanitize=undefined",
    };

    lib.linkLibC();
    lib.addCSourceFiles(&common_sources, &cflags);
    lib.addIncludePath(.{ .path = nats_src_prefix ++ "include" });
    // if building with streaming support (protocol.pb-c.c includes
    // <protobuf-c/protobuf-c.h>, unfortunately)
    lib.addIncludePath(.{ .path = "deps" });
    lib.addIncludePath(.{ .path = nats_src_prefix ++ "stan" });
    lib.addCSourceFiles(&streaming_sources, &cflags);
    lib.addCSourceFiles(&protobuf_c_sources, &cflags);

    const ssl_dep = b.dependency("libressl", .{
        .target = options.target,
        .optimize = options.optimize,
    });

    const tinfo = lib.target_info.target;
    switch (tinfo.os.tag) {
        .windows => {
            lib.addCSourceFiles(&win_sources, &cflags);
            if (tinfo.abi != .msvc) {
                lib.addCSourceFiles(&.{"src/win-crosshack.c"}, &cflags);
            }
            lib.defineCMacro("_WIN32", null);
            lib.linkSystemLibrary("ws2_32");
        },
        .macos => {
            lib.addCSourceFiles(&unix_sources, &cflags);
            lib.defineCMacro("DARWIN", null);
        },
        else => {
            lib.addCSourceFiles(&unix_sources, &cflags);
            lib.defineCMacro("_GNU_SOURCE", null);
            lib.defineCMacro("LINUX", null);
            // may need to link pthread and rt. Not sure if those are included with linkLibC
            lib.linkSystemLibrary("pthread");
            lib.linkSystemLibrary("rt");
        },
    }

    lib.defineCMacro("NATS_HAS_TLS", null);
    lib.defineCMacro("NATS_USE_OPENSSL_1_1", null);
    lib.defineCMacro("NATS_FORCE_HOST_VERIFICATION", null);
    lib.defineCMacro("NATS_HAS_STREAMING", null);
    lib.defineCMacro("_REENTRANT", null);

    inline for (install_headers) |header| {
        lib.installHeader(nats_src_prefix ++ header, "nats/" ++ header);
    }

    lib.linkLibrary(ssl_dep.artifact("ssl"));

    b.installArtifact(lib);

    return lib;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = nats_c_lib(b, .{ .name = "nats-c", .target = target, .optimize = optimize });
}

const nats_src_prefix = "deps/nats.c/src/";

const install_headers = [_][]const u8{
    "nats.h",
    "status.h",
    "version.h",
};

const common_sources = [_][]const u8{
    nats_src_prefix ++ "asynccb.c",
    nats_src_prefix ++ "comsock.c",
    nats_src_prefix ++ "crypto.c",
    nats_src_prefix ++ "js.c",
    nats_src_prefix ++ "kv.c",
    nats_src_prefix ++ "nats.c",
    nats_src_prefix ++ "nkeys.c",
    nats_src_prefix ++ "opts.c",
    nats_src_prefix ++ "pub.c",
    nats_src_prefix ++ "stats.c",
    nats_src_prefix ++ "sub.c",
    nats_src_prefix ++ "url.c",
    nats_src_prefix ++ "buf.c",
    nats_src_prefix ++ "conn.c",
    nats_src_prefix ++ "hash.c",
    nats_src_prefix ++ "jsm.c",
    nats_src_prefix ++ "msg.c",
    nats_src_prefix ++ "natstime.c",
    nats_src_prefix ++ "nuid.c",
    nats_src_prefix ++ "parser.c",
    nats_src_prefix ++ "srvpool.c",
    nats_src_prefix ++ "status.c",
    nats_src_prefix ++ "timer.c",
    nats_src_prefix ++ "util.c",
};

const unix_sources = [_][]const u8{
    nats_src_prefix ++ "unix/cond.c",
    nats_src_prefix ++ "unix/mutex.c",
    nats_src_prefix ++ "unix/sock.c",
    nats_src_prefix ++ "unix/thread.c",
};

const win_sources = [_][]const u8{
    nats_src_prefix ++ "win/cond.c",
    nats_src_prefix ++ "win/mutex.c",
    nats_src_prefix ++ "win/sock.c",
    nats_src_prefix ++ "win/strings.c",
    nats_src_prefix ++ "win/thread.c",
};

const streaming_sources = [_][]const u8{
    nats_src_prefix ++ "stan/conn.c",
    nats_src_prefix ++ "stan/copts.c",
    nats_src_prefix ++ "stan/msg.c",
    nats_src_prefix ++ "stan/protocol.pb-c.c",
    nats_src_prefix ++ "stan/pub.c",
    nats_src_prefix ++ "stan/sopts.c",
    nats_src_prefix ++ "stan/sub.c",
};

const protobuf_c_sources = [_][]const u8{
    "deps/protobuf-c/protobuf-c.c",
};
