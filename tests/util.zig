// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const KeyCert = struct { key: [:0]const u8, cert: [:0]const u8 };
const server_rsa: KeyCert = .{
    .key = @embedFile("./data/server-rsa.key"),
    .cert = @embedFile("./data/server-rsa.cert"),
};

const server_ecc: KeyCert = .{
    .key = @embedFile("./data/server-ecc.key"),
    .cert = @embedFile("./data/server-ecc.cert"),
};

const TestLaunchError = error{
    NoLaunchStringFound,
};

pub const TestServer = struct {
    allocator: std.mem.Allocator,
    process: std.process.Child,
    key_dir: ?std.testing.TmpDir,
    url: [:0]u8,

    pub const LaunchOptions = struct {
        executable: []const u8 = "nats-server",
        port: u16 = 4222,
        auth: union(enum) {
            none: void,
            token: []const u8,
            password: struct { user: []const u8, pass: []const u8 },
        } = .none,
        tls: enum {
            none,
            rsa,
            ecc,
        } = .none,
        allocator: std.mem.Allocator = std.testing.allocator,

        pub fn connectionString(self: LaunchOptions) ![:0]u8 {
            const authstr: []u8 = switch (self.auth) {
                // dupe this so we don't have to handle an edge case where it
                // does not need to be freed
                .none => try self.allocator.dupe(u8, ""),
                .token => |tok| try std.fmt.allocPrint(
                    self.allocator,
                    "{s}@",
                    .{tok},
                ),
                .password => |auth| try std.fmt.allocPrint(
                    self.allocator,
                    "{s}:{s}@",
                    .{ auth.user, auth.pass },
                ),
            };
            defer self.allocator.free(authstr);

            return try std.fmt.allocPrintZ(self.allocator, "nats://{s}127.0.0.1:{d}", .{ authstr, self.port });
        }
    };

    pub fn launch(options: LaunchOptions) !TestServer {
        var portbuf = [_]u8{0} ** 5;
        const strport = try std.fmt.bufPrint(&portbuf, "{d}", .{options.port});

        var key_dir: ?std.testing.TmpDir = null;
        var key_path: ?[]const u8 = null;
        var cert_path: ?[]const u8 = null;

        errdefer if (key_dir) |*kd| kd.cleanup();

        // ChildProcess copies these, so we can free them before the process has
        // closed.
        defer {
            if (key_path) |kp| options.allocator.free(kp);
            if (cert_path) |cp| options.allocator.free(cp);
        }

        const args: [][]const u8 = blk: {
            const executable: []const []const u8 = &.{options.executable};
            const listen: []const []const u8 = &.{ "-a", "127.0.0.1" };
            const port: []const []const u8 = &.{ "-p", strport };
            const auth: []const []const u8 = switch (options.auth) {
                .none => &[_][]const u8{},
                .token => |tok| &[_][]const u8{ "--auth", tok },
                .password => |auth| &[_][]const u8{ "--user", auth.user, "--pass", auth.pass },
            };
            const tls: []const []const u8 = switch (options.tls) {
                .none => &[_][]const u8{},
                .rsa, .ecc => |keytype| keyb: {
                    const pair = switch (keytype) {
                        .rsa => server_rsa,
                        .ecc => server_ecc,
                        else => unreachable,
                    };

                    const out_dir = std.testing.tmpDir(.{});
                    key_dir = out_dir;

                    try out_dir.dir.writeFile(.{ .sub_path = "server.key", .data = pair.key });
                    try out_dir.dir.writeFile(.{ .sub_path = "server.cert", .data = pair.cert });
                    // since testing.tmpDir will actually bury itself in zig-cache/tmp,
                    // there's not an easy way to extract files from within the temp
                    // directory except through using realPath, as far as I can tell
                    // (or reproducing the path naming logic, but that seems fragile).
                    const out_key = try out_dir.dir.realpathAlloc(options.allocator, "server.key");
                    const out_cert = try out_dir.dir.realpathAlloc(options.allocator, "server.cert");

                    key_path = out_key;
                    cert_path = out_cert;
                    break :keyb &[_][]const u8{ "--tls", "--tlscert", out_cert, "--tlskey", out_key };
                },
            };

            break :blk try std.mem.concat(
                options.allocator,
                []const u8,
                &.{ executable, listen, port, auth, tls },
            );
        };

        defer options.allocator.free(args);

        var child = std.process.Child.init(args, options.allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();
        var poller = std.io.poll(options.allocator, enum { stderr }, .{ .stderr = child.stderr.? });
        defer poller.deinit();

        while (try poller.poll()) {
            if (std.mem.indexOf(u8, poller.fifo(.stderr).buf, "[INF] Server is ready")) |_| {
                return .{
                    .allocator = options.allocator,
                    .process = child,
                    .key_dir = key_dir,
                    .url = try options.connectionString(),
                };
            }
        }

        _ = try child.kill();
        std.debug.print("output: {s}\n", .{poller.fifo(.stderr).buf});
        return error.NoLaunchStringFound;
    }

    pub fn stop(self: *TestServer) void {
        if (self.key_dir) |*key_dir| key_dir.cleanup();
        self.allocator.free(self.url);
        _ = self.process.kill() catch return;
    }
};
