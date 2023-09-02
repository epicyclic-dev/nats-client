// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const TestLaunchError = error{
    NoLaunchStringFound,
};

pub const TestServer = struct {
    process: std.ChildProcess,

    pub const LaunchOptions = struct {
        executable: []const u8 = "nats-server",
        port: u16 = 4222,
        auth: union(enum) {
            none: void,
            token: []const u8,
            password: struct { user: []const u8, pass: []const u8 },
        } = .none,
        allocator: std.mem.Allocator = std.testing.allocator,

        fn argLen(self: LaunchOptions) usize {
            // executable, -a, 127.0.0.1, -p, 4222
            const base_len: usize = 5;
            return base_len + switch (self.auth) {
                .none => @as(usize, 0),
                .token => @as(usize, 2),
                .password => @as(usize, 4),
            };
        }
    };

    pub fn launch(options: LaunchOptions) !TestServer {
        // const allocator = std.testing.allocator;
        var portbuf = [_]u8{0} ** 5;
        const strport = try std.fmt.bufPrint(&portbuf, "{d}", .{options.port});

        const argsbuf: [9][]const u8 = blk: {
            const executable: [1][]const u8 = .{options.executable};
            const listen: [2][]const u8 = .{ "-a", "127.0.0.1" };
            const port: [2][]const u8 = .{ "-p", strport };
            const auth: [4][]const u8 = switch (options.auth) {
                .none => .{""} ** 4,
                .token => |tok| .{ "--auth", tok, "", "" },
                .password => |auth| .{ "--user", auth.user, "--pass", auth.pass },
            };

            break :blk executable ++ listen ++ port ++ auth;
        };

        const args = argsbuf[0..options.argLen()];

        var child = std.ChildProcess.init(args, options.allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        try child.spawn();
        var poller = std.io.poll(options.allocator, enum { stderr }, .{ .stderr = child.stderr.? });
        defer poller.deinit();

        while (try poller.poll()) {
            if (std.mem.indexOf(u8, poller.fifo(.stderr).buf, "[INF] Server is ready")) |_| {
                return .{ .process = child };
            }
        }

        _ = try child.kill();
        std.debug.print("output: {s}\n", .{poller.fifo(.stderr).buf});
        return error.NoLaunchStringFound;
    }

    pub fn stop(self: *TestServer) void {
        _ = self.process.kill() catch return;
    }
};
