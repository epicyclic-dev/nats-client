// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

const std = @import("std");

const nats = @import("nats");

const util = @import("./util.zig");

const rsa_key = @embedFile("./data/client-rsa.key");
const rsa_cert = @embedFile("./data/client-rsa.cert");
const ecc_key = @embedFile("./data/client-ecc.key");
const ecc_cert = @embedFile("./data/client-ecc.cert");

test "nats.Connection.connectTo" {
    {
        var server = try util.TestServer.launch(.{});
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo(server.url);
        defer connection.destroy();
    }

    {
        var server = try util.TestServer.launch(.{
            .auth = .{ .token = "test_token" },
        });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo(server.url);
        defer connection.destroy();
    }

    {
        var server = try util.TestServer.launch(.{ .auth = .{
            .password = .{ .user = "user", .pass = "password" },
        } });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const connection = try nats.Connection.connectTo(server.url);
        defer connection.destroy();
        connection.close();
    }
}

test "nats.Connection" {
    var server = try util.TestServer.launch(.{});
    defer server.stop();

    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const connection = try nats.Connection.connectTo(server.url);
    defer connection.destroy();

    _ = connection.isClosed();
    _ = connection.isReconnecting();
    _ = connection.getStatus();
    _ = connection.bytesBuffered();
    try connection.flush();
    try connection.flushTimeout(100);
    _ = connection.getMaxPayload();
    _ = try connection.getStats();
    {
        // id is 56 bytes plus terminating zero
        var buf = [_]u8{0} ** 57;
        _ = try connection.getConnectedUrl(&buf);
        _ = try connection.getConnectedServerId(&buf);
    }
    {
        var servers = try connection.getServers();
        defer servers.deinit();

        var discovered = try connection.getDiscoveredServers();
        defer discovered.deinit();
    }

    _ = connection.getLastError();
    _ = try connection.getClientId();
    // our connection does not have a JWT, so this call will always fail
    _ = connection.sign("greetings") catch {};
    _ = try connection.getLocalIpAndPort();
    _ = connection.getRtt() catch {};
    _ = connection.hasHeaderSupport();
    // this closes the connection, but it does not block until the connection is closed,
    // which can result in nondeterministic behavior for calls after this one.
    try connection.drain();
    // this will return error.ConnectionClosed if the connection is already closed, so
    // don't expect this to be error free.
    connection.drainTimeout(1000) catch {};
}

fn callbacks(comptime UDT: type) type {
    return struct {
        fn reconnectDelayHandler(userdata: UDT, connection: *nats.Connection, attempts: c_int) i64 {
            _ = userdata;
            _ = connection;
            _ = attempts;

            return 0;
        }

        fn errorHandler(
            userdata: UDT,
            connection: *nats.Connection,
            subscription: *nats.Subscription,
            status: nats.Status,
        ) void {
            _ = userdata;
            _ = connection;
            _ = subscription;
            _ = status;
        }

        fn connectionHandler(userdata: UDT, connection: *nats.Connection) void {
            _ = userdata;
            _ = connection;
        }

        fn jwtHandler(userdata: UDT) nats.JwtResponseOrError {
            _ = userdata;
            // return .{ .jwt = std.heap.raw_c_allocator.dupeZ(u8, "abcdef") catch @panic("no!") };
            return .{ .error_message = std.heap.raw_c_allocator.dupeZ(u8, "dang") catch @panic("no!") };
        }

        fn signatureHandler(userdata: UDT, nonce: [:0]const u8) nats.SignatureResponseOrError {
            _ = userdata;
            _ = nonce;
            // return .{ .signature = std.heap.raw_c_allocator.dupe(u8, "01230123") catch @panic("no!") };
            return .{ .error_message = std.heap.raw_c_allocator.dupeZ(u8, "whoops") catch @panic("no!") };
        }
    };
}

test "nats.ConnectionOptions" {
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const options = try nats.ConnectionOptions.create();
    defer options.destroy();

    const userdata: u32 = 0;

    try options.setUrl(nats.default_server_url);
    const servers = [_][*:0]const u8{ "nats://127.0.0.1:4442", "nats://127.0.0.1:4443" };
    try options.setServers(&servers);
    try options.setCredentials("user", "password");
    try options.setToken("test_token");
    try options.setNoRandomize(false);
    try options.setTimeout(1000);
    try options.setName("name");

    try options.setVerbose(true);
    try options.setPedantic(true);
    try options.setPingInterval(1000);
    try options.setMaxPingsOut(100);
    try options.setIoBufSize(1024);
    try options.setAllowReconnect(false);
    try options.setMaxReconnect(10);
    try options.setReconnectWait(500);
    try options.setReconnectJitter(100, 200);
    try options.setCustomReconnectDelay(*const u32, callbacks(*const u32).reconnectDelayHandler, &userdata);
    try options.setCustomReconnectDelay(void, callbacks(void).reconnectDelayHandler, {});
    try options.setCustomReconnectDelay(?*const u32, callbacks(?*const u32).reconnectDelayHandler, null);
    try options.setReconnectBufSize(1024);
    try options.setMaxPendingMessages(50);
    try options.setErrorHandler(*const u32, callbacks(*const u32).errorHandler, &userdata);
    try options.setErrorHandler(void, callbacks(void).errorHandler, {});
    try options.setErrorHandler(?*const u32, callbacks(?*const u32).errorHandler, null);
    try options.setClosedCallback(*const u32, callbacks(*const u32).connectionHandler, &userdata);
    try options.setClosedCallback(void, callbacks(void).connectionHandler, {});
    try options.setClosedCallback(?*const u32, callbacks(?*const u32).connectionHandler, null);
    try options.setDisconnectedCallback(*const u32, callbacks(*const u32).connectionHandler, &userdata);
    try options.setDisconnectedCallback(void, callbacks(void).connectionHandler, {});
    try options.setDisconnectedCallback(?*const u32, callbacks(?*const u32).connectionHandler, null);
    try options.setDiscoveredServersCallback(*const u32, callbacks(*const u32).connectionHandler, &userdata);
    try options.setDiscoveredServersCallback(void, callbacks(void).connectionHandler, {});
    try options.setDiscoveredServersCallback(?*const u32, callbacks(?*const u32).connectionHandler, null);
    try options.setLameDuckModeCallback(*const u32, callbacks(*const u32).connectionHandler, &userdata);
    try options.setLameDuckModeCallback(void, callbacks(void).connectionHandler, {});
    try options.setLameDuckModeCallback(?*const u32, callbacks(?*const u32).connectionHandler, null);
    try options.ignoreDiscoveredServers(true);
    try options.useGlobalMessageDelivery(false);
    try options.ipResolutionOrder(.ipv4_first);
    try options.setSendAsap(true);
    try options.useOldRequestStyle(false);
    try options.setFailRequestsOnDisconnect(true);
    try options.setNoEcho(true);
    try options.setRetryOnFailedConnect(*const u32, callbacks(*const u32).connectionHandler, true, &userdata);
    try options.setRetryOnFailedConnect(void, callbacks(void).connectionHandler, true, {});
    try options.setRetryOnFailedConnect(?*const u32, callbacks(?*const u32).connectionHandler, true, null);
    try options.setUserCredentialsCallbacks(*const u32, *const u32, callbacks(*const u32).jwtHandler, callbacks(*const u32).signatureHandler, &userdata, &userdata);
    try options.setUserCredentialsCallbacks(void, void, callbacks(void).jwtHandler, callbacks(void).signatureHandler, {}, {});
    try options.setWriteDeadline(5);
    try options.disableNoResponders(true);
    try options.setCustomInboxPrefix("_FOOBOX");
    try options.setMessageBufferPadding(123);
}

fn tokenHandler(userdata: *u32) [:0]const u8 {
    _ = userdata;
    return "token";
}

test "nats.ConnectionOptions (crypto edition)" {
    try nats.init(nats.default_spin_count);
    defer nats.deinit();

    const options = try nats.ConnectionOptions.create();
    defer options.destroy();
    var userdata: u32 = 0;

    try options.setTokenHandler(*u32, tokenHandler, &userdata);
    try options.setSecure(false);
    try options.setCertificatesChain(rsa_cert, rsa_key);
    try options.setCiphers("-ALL:HIGH");
    try options.setCipherSuites("TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256");
    try options.setExpectedHostname("test.nats.zig");
    try options.skipServerVerification(true);
}

test "nats.ConnectionOptions (crypto connect)" {
    {
        var server = try util.TestServer.launch(.{ .tls = .rsa });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const options = try nats.ConnectionOptions.create();
        defer options.destroy();

        try options.setSecure(true);
        try options.skipServerVerification(true);
        try options.setCertificatesChain(rsa_cert, rsa_key);

        const connection = try nats.Connection.connect(options);
        defer connection.destroy();

        try connection.publish("foo", "bar");
    }

    {
        var server = try util.TestServer.launch(.{ .tls = .ecc });
        defer server.stop();

        try nats.init(nats.default_spin_count);
        defer nats.deinit();

        const options = try nats.ConnectionOptions.create();
        defer options.destroy();

        try options.setSecure(true);
        try options.skipServerVerification(true);
        try options.setCertificatesChain(ecc_cert, ecc_key);

        const connection = try nats.Connection.connect(options);
        defer connection.destroy();

        try connection.publish("foo", "bar");
    }
}
