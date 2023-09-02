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

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const sub_ = @import("./subscription.zig");
const Subscription = sub_.Subscription;
const SubscriptionCallbackSignature = sub_.SubscriptionCallbackSignature;
const makeSubscriptionCallbackThunk = sub_.makeSubscriptionCallbackThunk;

const msg_ = @import("./message.zig");
const Message = msg_.Message;

const err_ = @import("./error.zig");
const Error = err_.Error;
const Status = err_.Status;
const ErrorInfo = err_.ErrorInfo;

const sta_ = @import("./statistics.zig");
const Statistics = sta_.Statistics;
const StatsCounts = sta_.StatsCounts;

const thunk = @import("./thunk.zig");

pub const default_server_url: [:0]const u8 = nats_c.NATS_DEFAULT_URL;

pub const ConnectionStatus = enum(c_int) {
    disconnected = nats_c.DISCONNECTED,
    connecting = nats_c.CONNECTING,
    connected = nats_c.CONNECTED,
    closed = nats_c.CLOSED,
    reconnecting = nats_c.RECONNECTING,
    draining_subs = nats_c.DRAINING_SUBS,
    draining_pubs = nats_c.DRAINING_PUBS,
    _,

    pub fn fromInt(int: c_uint) ConnectionStatus {
        return @enumFromInt(int);
    }
};

pub const AddressPort = struct {
    address: [:0]u8,
    port: u16,
};

pub const Connection = opaque {
    pub fn create(options: *ConnectionOptions) Error!*Connection {
        var self: *Connection = undefined;
        const status = Status.fromInt(nats_c.natsConnection_Connect(@ptrCast(&self), @ptrCast(options)));
        return status.toError() orelse self;
    }

    pub fn connectTo(urls: [:0]const u8) Error!*Connection {
        var self: *Connection = undefined;
        const status = Status.fromInt(
            nats_c.natsConnection_ConnectTo(@ptrCast(&self), urls.ptr),
        );

        return status.toError() orelse self;
    }

    pub fn close(self: *Connection) void {
        return nats_c.natsConnection_Close(@ptrCast(self));
    }

    pub fn destroy(self: *Connection) void {
        return nats_c.natsConnection_Destroy(@ptrCast(self));
    }

    pub fn processReadEvent(self: *Connection) void {
        nats_c.natsConnection_ProcessReadEvent(@ptrCast(self));
    }

    pub fn processWriteEvent(self: *Connection) void {
        nats_c.natsConnection_ProcessWriteEvent(@ptrCast(self));
    }

    pub fn isClosed(self: *Connection) bool {
        return nats_c.natsConnection_IsClosed(@ptrCast(self));
    }

    pub fn isReconnecting(self: *Connection) bool {
        return nats_c.natsConnection_IsReconnecting(@ptrCast(self));
    }

    pub fn getStatus(self: *Connection) ConnectionStatus {
        return ConnectionStatus.fromInt(nats_c.natsConnection_Status(@ptrCast(self)));
    }

    pub fn bytesBuffered(self: *Connection) c_int {
        return nats_c.natsConnection_Buffered(@ptrCast(self));
    }

    pub fn flush(self: *Connection) Error!void {
        return Status.fromInt(nats_c.natsConnection_Flush(@ptrCast(self))).raise();
    }

    pub fn flushTimeout(self: *Connection, timeout: i64) Error!void {
        return Status.fromInt(nats_c.natsConnection_FlushTimeout(@ptrCast(self), timeout)).raise();
    }

    pub fn getMaxPayload(self: *Connection) c_int {
        return nats_c.natsConnection_GetMaxPayload(@ptrCast(self));
    }

    pub fn getStats(self: *Connection) Error!StatsCounts {
        var stats = try Statistics.create();
        defer stats.destroy();

        const status = Status.fromInt(
            nats_c.natsConnection_GetStats(@ptrCast(self), @ptrCast(stats)),
        );

        return status.toError() orelse stats.getCounts();
    }

    pub fn getConnectedUrl(self: *Connection, buffer: []u8) Error![:0]u8 {
        const status = Status.fromInt(
            nats_c.natsConnection_GetConnectedUrl(@ptrCast(self), buffer.ptr, buffer.len),
        );

        // cast this to a c pointer so that sliceTo properly returns the sentinel
        // terminated type, which is guaranteed by the backing library.
        return status.toError() orelse std.mem.sliceTo(@as([*c]u8, buffer.ptr), 0);
    }

    pub fn getConnectedServerId(self: *Connection, buffer: []u8) Error![:0]u8 {
        const status = Status.fromInt(
            nats_c.natsConnection_GetConnectedServerId(@ptrCast(self), buffer.ptr, buffer.len),
        );

        // cast this to a c pointer so that sliceTo properly returns the sentinel
        // terminated type, which is guaranteed by the backing library.
        return status.toError() orelse std.mem.sliceTo(@as([*c]u8, buffer.ptr), 0);
    }

    pub fn getServers(self: *Connection) Error![][*:0]u8 {
        var servers: [*][*:0]u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(
            nats_c.natsConnection_GetServers(@ptrCast(self), &servers, &count),
        );

        return status.toError() orelse servers[0..@intCast(count)];
    }

    pub fn getDiscoveredServers(self: *Connection) Error![][*:0]u8 {
        var servers: [*][*:0]u8 = undefined;
        var count: c_int = 0;

        const status = Status.fromInt(
            nats_c.natsConnection_GetDiscoveredServers(@ptrCast(self), &servers, &count),
        );

        return status.toError() orelse servers[0..@intCast(count)];
    }

    pub fn getLastError(self: *Connection) ErrorInfo {
        var desc: [*:0]const u8 = 0;
        const status = nats_c.natsConnection_GetLastError(@ptrCast(self), &desc);

        return .{
            .code = Status.fromInt(status).toError(),
            .desc = std.mem.sliceTo(desc, 0),
        };
    }

    pub fn getClientId(self: *Connection) Error!u64 {
        var id: u64 = 0;

        const status = Status.fromInt(
            nats_c.natsConnection_GetClientID(@ptrCast(self), &id),
        );

        return status.toError() orelse id;
    }

    pub fn drain(self: *Connection) Error!void {
        return Status.fromInt(nats_c.natsConnection_Drain(@ptrCast(self))).raise();
    }

    pub fn drainTimeout(self: *Connection, timeout: i64) Error!void {
        return Status.fromInt(nats_c.natsConnection_DrainTimeout(@ptrCast(self), timeout)).raise();
    }

    pub fn sign(self: *Connection, message: []const u8) Error![64]u8 {
        var sig = [_]u8{0} ** 64;

        const status = Status.fromInt(
            nats_c.natsConnection_Sign(@ptrCast(self), message.ptr, message.len, &sig),
        );

        return status.toError() orelse sig;
    }

    pub fn getClientIp(self: *Connection) Error![:0]u8 {
        var ip: [*c]u8 = null;

        const status = Status.fromInt(
            nats_c.natsConnection_GetClientIP(@ptrCast(self), &ip),
        );

        return status.toError() orelse std.mem.sliceTo(ip, 0);
    }

    pub fn getLocalIpAndPort(self: *Connection) Error!AddressPort {
        var address: [*:0]u8 = undefined;
        var port: c_int = 0;

        const status = Status.fromInt(
            nats_c.natsConnection_GetLocalIPAndPort(@ptrCast(self), &address, &port),
        );

        return status.toError() orelse .{
            .address = std.mem.sliceTo(address, 0),
            .port = @intCast(port),
        };
    }

    pub fn getRtt(self: *Connection) Error!i64 {
        var rtt: i64 = 0;

        const status = Status.fromInt(
            nats_c.natsConnection_GetRTT(@ptrCast(self), &rtt),
        );

        return status.toError() orelse rtt;
    }

    pub fn hasHeaderSupport(self: *Connection) bool {
        const status = Status.fromInt(
            nats_c.natsConnection_HasHeaderSupport(@ptrCast(self)),
        );

        return status == .okay;
    }

    pub fn publish(self: *Connection, subject: [:0]const u8, message: []const u8) Error!void {
        return Status.fromInt(
            nats_c.natsConnection_Publish(@ptrCast(self), subject, message.ptr, @intCast(message.len)),
        ).raise();
    }

    pub fn publishMessage(self: *Connection, message: *Message) Error!void {
        return Status.fromInt(
            nats_c.natsConnection_PublishMsg(@ptrCast(self), @ptrCast(message)),
        ).raise();
    }

    pub fn publishRequest(
        self: *Connection,
        subject: [:0]const u8,
        reply: [:0]const u8,
        message: []const u8,
    ) Error!void {
        return Status.fromInt(
            nats_c.natsConnection_PublishRequest(
                @ptrCast(self),
                subject.ptr,
                reply.ptr,
                message.ptr,
                @intCast(message.len),
            ),
        ).raise();
    }

    pub fn request(
        self: *Connection,
        subject: [:0]const u8,
        req: []const u8,
        timeout: i64,
    ) Error!*Message {
        var response: *Message = undefined;

        const status = Status.fromInt(nats_c.natsConnection_Request(
            @ptrCast(&response),
            @ptrCast(self),
            subject.ptr,
            req.ptr,
            @intCast(req.len),
            timeout,
        ));

        return status.toError() orelse response;
    }

    pub fn requestMessage(
        self: *Connection,
        req: *Message,
        timeout: i64,
    ) Error!*Message {
        var response: *Message = undefined;

        const status = Status.fromInt(nats_c.natsConnection_RequestMsg(
            @ptrCast(&response),
            @ptrCast(self),
            @ptrCast(req),
            timeout,
        ));

        return status.toError() orelse response;
    }

    pub fn subscribe(
        self: *Connection,
        comptime T: type,
        subject: [:0]const u8,
        callback: SubscriptionCallbackSignature(T),
        userdata: *T,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;
        const status = Status.fromInt(nats_c.natsConnection_Subscribe(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
            makeSubscriptionCallbackThunk(T, callback),
            userdata,
        ));
        return status.toError() orelse sub;
    }

    pub fn subscribeTimeout(
        self: *Connection,
        comptime T: type,
        subject: [:0]const u8,
        timeout: i64,
        callback: SubscriptionCallbackSignature(T),
        userdata: *T,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;

        const status = Status.fromInt(nats_c.natsConnection_SubscribeTimeout(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
            timeout,
            makeSubscriptionCallbackThunk(T, callback),
            userdata,
        ));

        return status.toError() orelse sub;
    }

    pub fn subscribeSync(self: *Connection, subject: [:0]const u8) Error!*Subscription {
        var sub: *Subscription = undefined;

        const status = Status.fromInt(nats_c.natsConnection_SubscribeSync(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
        ));

        return status.toError() orelse sub;
    }

    pub fn queueSubscribe(
        self: *Connection,
        comptime T: type,
        subject: [:0]const u8,
        queue_group: [:0]const u8,
        callback: SubscriptionCallbackSignature(T),
        userdata: *T,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;

        const status = Status.fromInt(nats_c.natsConnection_QueueSubscribe(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
            queue_group.ptr,
            makeSubscriptionCallbackThunk(T, callback),
            userdata,
        ));

        return status.toError() orelse sub;
    }

    pub fn queueSubscribeTimeout(
        self: *Connection,
        comptime T: type,
        subject: [:0]const u8,
        queue_group: [:0]const u8,
        timeout: i64,
        callback: SubscriptionCallbackSignature(T),
        userdata: *T,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;

        const status = Status.fromInt(nats_c.natsConnection_QueueSubscribe(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
            queue_group.ptr,
            timeout,
            makeSubscriptionCallbackThunk(T, callback),
            userdata,
        ));

        return status.toError() orelse sub;
    }

    pub fn queueSubscribeSync(
        self: *Connection,
        subject: [:0]const u8,
        queue_group: [:0]const u8,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;

        const status = Status.fromInt(nats_c.natsConnection_SubscribeSync(
            @ptrCast(&sub),
            @ptrCast(self),
            subject.ptr,
            queue_group.ptr,
        ));

        return status.toError() orelse sub;
    }
};

pub const ConnectionOptions = opaque {
    pub fn create() Error!*ConnectionOptions {
        var self: *ConnectionOptions = undefined;
        const status = Status.fromInt(nats_c.natsOptions_Create(@ptrCast(&self)));

        return status.toError() orelse self;
    }

    pub fn destroy(self: *ConnectionOptions) void {
        nats_c.natsOptions_Destroy(@ptrCast(self));
    }

    pub fn setUrl(self: *ConnectionOptions, url: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetURL(@ptrCast(self), url.ptr),
        ).raise();
    }

    pub fn setServers(self: *ConnectionOptions, servers: []const [*:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetServers(
                @ptrCast(self),
                @constCast(@ptrCast(servers.ptr)),
                @intCast(servers.len),
            ),
        ).raise();
    }

    pub fn setCredentials(self: *ConnectionOptions, user: [:0]const u8, password: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetUserInfo(
                @ptrCast(self),
                user.ptr,
                password.ptr,
            ),
        ).raise();
    }

    pub fn setToken(self: *ConnectionOptions, token: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetToken(@ptrCast(self), token.ptr),
        ).raise();
    }

    pub fn setTokenHandler(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const TokenCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetTokenHandler(
            @ptrCast(self),
            makeTokenCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setNoRandomize(self: *ConnectionOptions, no: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetNoRandomize(@ptrCast(self), no),
        ).raise();
    }

    pub fn setTimeout(self: *ConnectionOptions, timeout: i64) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetTimeout(@ptrCast(self), timeout),
        ).raise();
    }

    pub fn setName(self: *ConnectionOptions, name: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetName(@ptrCast(self), name.ptr),
        ).raise();
    }

    pub fn setSecure(self: *ConnectionOptions, secure: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetSecure(@ptrCast(self), secure),
        ).raise();
    }

    pub fn loadCaTrustedCertificates(self: *ConnectionOptions, filename: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_LoadCATrustedCertificates(@ptrCast(self), filename.ptr),
        ).raise();
    }

    pub fn setCaTrustedCertificates(self: *ConnectionOptions, certificates: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCATrustedCertificates(@ptrCast(self), certificates.ptr),
        ).raise();
    }

    pub fn loadCertificatesChain(self: *ConnectionOptions, certs_filename: [:0]const u8, key_filename: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_LoadCertificatesChain(@ptrCast(self), certs_filename.ptr, key_filename.ptr),
        ).raise();
    }

    pub fn setCertificatesChain(self: *ConnectionOptions, cert: [:0]const u8, key: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCertificatesChain(@ptrCast(self), cert.ptr, key.ptr),
        ).raise();
    }

    pub fn setCiphers(self: *ConnectionOptions, ciphers: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCiphers(@ptrCast(self), ciphers.ptr),
        ).raise();
    }

    pub fn setCipherSuites(self: *ConnectionOptions, ciphers: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCipherSuites(@ptrCast(self), ciphers.ptr),
        ).raise();
    }

    pub fn setExpectedHostname(self: *ConnectionOptions, hostname: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetExpectedHostname(@ptrCast(self), hostname.ptr),
        ).raise();
    }

    pub fn skipServerVerification(self: *ConnectionOptions, skip: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SkipServerVerification(@ptrCast(self), skip),
        ).raise();
    }

    pub fn setVerbose(self: *ConnectionOptions, verbose: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetVerbose(@ptrCast(self), verbose),
        ).raise();
    }

    pub fn setPedantic(self: *ConnectionOptions, pedantic: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetPedantic(@ptrCast(self), pedantic),
        ).raise();
    }

    pub fn setPingInterval(self: *ConnectionOptions, interval: i64) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetPingInterval(@ptrCast(self), interval),
        ).raise();
    }

    pub fn setMaxPingsOut(self: *ConnectionOptions, max: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetMaxPingsOut(@ptrCast(self), max),
        ).raise();
    }

    pub fn setIoBufSize(self: *ConnectionOptions, size: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetIOBufSize(@ptrCast(self), size),
        ).raise();
    }

    pub fn setAllowReconnect(self: *ConnectionOptions, allow: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetAllowReconnect(@ptrCast(self), allow),
        ).raise();
    }

    pub fn setMaxReconnect(self: *ConnectionOptions, max: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetMaxReconnect(@ptrCast(self), max),
        ).raise();
    }

    pub fn setReconnectWait(self: *ConnectionOptions, wait: i64) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetReconnectWait(@ptrCast(self), wait),
        ).raise();
    }

    pub fn setReconnectJitter(self: *ConnectionOptions, jitter: i64, jitter_tls: i64) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetReconnectJitter(@ptrCast(self), jitter, jitter_tls),
        ).raise();
    }

    pub fn setCustomReconnectDelay(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ReconnectDelayCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCustomReconnectDelay(
                @ptrCast(self),
                makeReconnectDelayCallbackThunk(T, callback),
                userdata,
            ),
        ).raise();
    }

    pub fn setReconnectBufSize(self: *ConnectionOptions, size: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetReconnectBufSize(@ptrCast(self), size),
        ).raise();
    }

    pub fn setMaxPendingMessages(self: *ConnectionOptions, max: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetMaxPendingMsgs(@ptrCast(self), max),
        ).raise();
    }

    pub fn setErrorHandler(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ErrorHandlerCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetErrorHandler(
                @ptrCast(self),
                makeErrorHandlerCallbackThunk(T, callback),
                userdata,
            ),
        ).raise();
    }

    pub fn setClosedCallback(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetClosedCB(
            @ptrCast(self),
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setDisconnectedCallback(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetClosedCB(
            @ptrCast(self),
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setReconnectedCallback(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetClosedCB(
            @ptrCast(self),
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setDiscoveredServersCallback(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetClosedCB(
            @ptrCast(self),
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setLameDuckModeCallback(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetClosedCB(
            @ptrCast(self),
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setEventLoop(
        self: *ConnectionOptions,
        comptime T: type,
        comptime L: type,
        comptime attach_callback: *const AttachEventLoopCallbackSignature(T, L),
        comptime read_callback: *const AttachEventLoopCallbackSignature(T),
        comptime write_callback: *const AttachEventLoopCallbackSignature(T),
        comptime detach_callback: *const thunk.SimpleCallbackSignature(T),
        loop: *L,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetEventLoop(
            @ptrCast(self),
            @ptrCast(loop),
            makeAttachEventLoopCallbackThunk(T, L, attach_callback),
            makeEventLoopAddRemoveCallbackThunk(T, read_callback),
            makeEventLoopAddRemoveCallbackThunk(T, write_callback),
            makeEventLoopDetachCallbackThunk(T, detach_callback),
        )).raise();
    }

    pub fn ignoreDiscoveredServers(self: *ConnectionOptions, ignore: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetIgnoreDiscoveredServers(@ptrCast(self), ignore),
        ).raise();
    }

    pub fn useGlobalMessageDelivery(self: *ConnectionOptions, use: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_UseGlobalMessageDelivery(@ptrCast(self), use),
        ).raise();
    }

    pub const IpResolutionOrder = enum(c_int) {
        any_order = 0,
        ipv4_only = 4,
        ipv6_only = 6,
        ipv4_first = 46,
        ipv6_first = 64,
    };

    pub fn ipResolutionOrder(self: *ConnectionOptions, order: IpResolutionOrder) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_IPResolutionOrder(@ptrCast(self), @intFromEnum(order)),
        ).raise();
    }

    pub fn setSendAsap(self: *ConnectionOptions, asap: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetSendAsap(@ptrCast(self), asap),
        ).raise();
    }

    pub fn useOldRequestStyle(self: *ConnectionOptions, old: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_UseOldRequestStyle(@ptrCast(self), old),
        ).raise();
    }

    pub fn setFailRequestsOnDisconnect(self: *ConnectionOptions, fail: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetFailRequestsOnDisconnect(@ptrCast(self), fail),
        ).raise();
    }

    pub fn setNoEcho(self: *ConnectionOptions, no: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetNoEcho(@ptrCast(self), no),
        ).raise();
    }

    pub fn setRetryOnFailedConnect(
        self: *ConnectionOptions,
        comptime T: type,
        comptime callback: *const ConnectionCallbackSignature(T),
        retry: bool,
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetRetryOnFailedConnect(
            @ptrCast(self),
            retry,
            makeConnectionCallbackThunk(T, callback),
            userdata,
        )).raise();
    }

    pub fn setUserCredentialsCallbacks(
        self: *ConnectionOptions,
        comptime T: type,
        comptime U: type,
        comptime jwt_callback: *const JwtHandlerCallbackSignature(T),
        comptime sig_callback: *const SignatureHandlerCallbackSignature(U),
        jwt_userdata: *T,
        sig_userdata: *U,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetUserCredentialsCallbacks(
            @ptrCast(self),
            makeJwtHandlerCallbackThunk(T, jwt_callback),
            jwt_userdata,
            makeSignatureHandlerCallbackThunk(U, sig_callback),
            sig_userdata,
        )).raise();
    }

    pub fn setUserCredentialsFromFiles(self: *ConnectionOptions, user_or_chained_file: [:0]const u8, seed_file: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetUserCredentialsFromFiles(
                @ptrCast(self),
                user_or_chained_file.ptr,
                seed_file.ptr,
            ),
        ).raise();
    }

    pub fn setUserCredentialsFromMemory(self: *ConnectionOptions, jwt_and_seed: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetUserCredentialsFromMemory(
                @ptrCast(self),
                jwt_and_seed.ptr,
            ),
        ).raise();
    }

    pub fn setNKey(
        self: *ConnectionOptions,
        comptime T: type,
        comptime sig_callback: *const SignatureHandlerCallbackSignature(T),
        pub_key: [:0]const u8,
        sig_userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetUserCredentialsCallbacks(
            @ptrCast(self),
            pub_key.ptr,
            makeSignatureHandlerCallbackThunk(T, sig_callback),
            sig_userdata,
        )).raise();
    }

    pub fn setNKeyFromSeed(self: *ConnectionOptions, pub_key: [:0]const u8, seed_file: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetNKeyFromSeed(
                @ptrCast(self),
                pub_key.ptr,
                seed_file.ptr,
            ),
        ).raise();
    }

    pub fn setWriteDeadline(self: *ConnectionOptions, deadline: i64) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetWriteDeadline(@ptrCast(self), deadline),
        ).raise();
    }

    pub fn disableNoResponders(self: *ConnectionOptions, no: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_DisableNoResponders(@ptrCast(self), no),
        ).raise();
    }

    pub fn setCustomInboxPrefix(self: *ConnectionOptions, prefix: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetCustomInboxPrefix(@ptrCast(self), prefix.ptr),
        ).raise();
    }

    pub fn setMessageBufferPadding(self: *ConnectionOptions, padding: c_int) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetMessageBufferPadding(@ptrCast(self), padding),
        ).raise();
    }
};

const TokenCallback = fn (?*anyopaque) callconv(.C) [*c]const u8;

pub fn TokenCallbackSignature(comptime T: type) type {
    return fn (*T) [:0]const u8;
}

fn makeTokenCallbackThunk(
    comptime T: type,
    comptime callback: *const TokenCallbackSignature(T),
) *const TokenCallback {
    return struct {
        fn thunk(userdata: ?*anyopaque) callconv(.C) [*c]const u8 {
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            return callback(data).ptr;
        }
    }.thunk;
}

const ConnectionCallback = fn (?*nats_c.natsConnection, ?*anyopaque) callconv(.C) void;

pub fn ConnectionCallbackSignature(comptime T: type) type {
    return fn (*T, *Connection) void;
}

fn makeConnectionCallbackThunk(
    comptime T: type,
    comptime callback: *const ConnectionCallbackSignature(T),
) *const ConnectionCallback {
    return struct {
        fn thunk(conn: ?*nats_c.natsConnection, userdata: ?*anyopaque) callconv(.C) void {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            callback(data, connection);
        }
    }.thunk;
}

const ReconnectDelayCallback = fn (?*nats_c.natsConnection, c_int, ?*anyopaque) callconv(.C) i64;

pub fn ReconnectDelayCallbackSignature(comptime T: type) type {
    return fn (*T, *Connection, c_int) i64;
}

fn makeReconnectDelayCallbackThunk(
    comptime T: type,
    comptime callback: *const ReconnectDelayCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            conn: ?*nats_c.natsConnection,
            attempts: c_int,
            userdata: ?*anyopaque,
        ) callconv(.C) i64 {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            return callback(data, connection, attempts);
        }
    }.thunk;
}

const ErrorHandlerCallback = fn (
    ?*nats_c.natsConnection,
    ?*nats_c.natsSubscription,
    nats_c.natsStatus,
    ?*anyopaque,
) callconv(.C) void;

pub fn ErrorHandlerCallbackSignature(comptime T: type) type {
    return fn (*T, *Connection, *Subscription, Status) void;
}

fn makeErrorHandlerCallbackThunk(
    comptime T: type,
    comptime callback: *const ErrorHandlerCallbackSignature(T),
) *const ErrorHandlerCallback {
    return struct {
        fn thunk(
            conn: ?*nats_c.natsConnection,
            sub: ?*nats_c.natsSubscription,
            status: nats_c.natsStatus,
            userdata: ?*anyopaque,
        ) callconv(.C) void {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const subscription: *Subscription = if (sub) |s| @ptrCast(s) else unreachable;
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;

            callback(data, connection, subscription, Status.fromInt(status));
        }
    }.thunk;
}

// natsSock is an fd on non-windows and SOCKET on windows
const AttachEventLoopCallback = fn (
    *?*anyopaque,
    ?*anyopaque,
    ?*nats_c.natsConnection,
    nats_c.natsSock,
) callconv(.C) nats_c.natsStatus;

pub fn AttachEventLoopCallbackSignature(comptime T: type, comptime L: type) type {
    return fn (*L, *Connection, c_int) anyerror!*T;
}

fn makeAttachEventLoopCallbackThunk(
    comptime T: type,
    comptime L: type,
    comptime callback: *const AttachEventLoopCallbackSignature(T, L),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            userdata: *?*anyopaque,
            loop: ?*anyopaque,
            conn: ?*nats_c.natsConnection,
            sock: ?*nats_c.natsSock,
        ) callconv(.C) nats_c.natsStatus {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const ev_loop: *L = if (loop) |l| @ptrCast(l) else unreachable;

            userdata.* = callback(ev_loop, connection, sock) catch |err|
                return Status.fromError(err).toInt();

            return nats_c.NATS_OK;
        }
    }.thunk;
}

const EventLoopAddRemoveCallback = fn (?*nats_c.natsConnection, c_int, ?*anyopaque) callconv(.C) nats_c.natsStatus;

pub fn EventLoopAddRemoveCallbackSignature(comptime T: type) type {
    return fn (*T, *Connection, c_int) anyerror!void;
}

fn makeEventLoopAddRemoveCallbackThunk(
    comptime T: type,
    comptime callback: *const EventLoopAddRemoveCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            conn: ?*nats_c.natsConnection,
            attempts: c_int,
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            callback(data, connection, attempts) catch |err|
                return Status.fromError(err).toInt();

            return nats_c.NATS_OK;
        }
    }.thunk;
}

const EventLoopDetachCallback = fn (?*anyopaque) callconv(.C) nats_c.natsStatus;

pub fn EventLoopDetachCallbackSignature(comptime T: type) type {
    return fn (*T) anyerror!void;
}

fn makeEventLoopDetachCallbackThunk(
    comptime T: type,
    comptime callback: *const EventLoopDetachCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            callback(data) catch |err| return Status.fromError(err).toInt();
            return nats_c.NATS_OK;
        }
    }.thunk;
}

// THE NATS LIBRARY WILL TRY TO FREE THE TOKEN AND ALSO THE ERROR MESSAGE, SO THEY MUST
// BE ALLOCATED WITH THE C ALLOCATOR
const JwtHandlerCallback = fn (?*?[*:0]u8, ?*?[*:0]u8, ?*anyopaque) callconv(.C) nats_c.natsStatus;

pub const JwtResponseOrError = union(enum) {
    jwt: [:0]u8,
    error_message: [:0]u8,
};

pub fn JwtHandlerCallbackSignature(comptime T: type) type {
    return fn (*T) JwtResponseOrError;
}

fn makeJwtHandlerCallbackThunk(
    comptime T: type,
    comptime callback: *const JwtHandlerCallbackSignature(T),
) *const JwtHandlerCallback {
    return struct {
        fn thunk(
            jwt_out_raw: ?*?[*:0]u8,
            err_out_raw: ?*?[*:0]u8,
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            const err_out = err_out_raw orelse unreachable;
            const jwt_out = jwt_out_raw orelse unreachable;

            switch (callback(data)) {
                .jwt => |jwt| {
                    jwt_out.* = jwt.ptr;
                    return nats_c.NATS_OK;
                },
                .error_message => |msg| {
                    err_out.* = msg.ptr;
                    return nats_c.NATS_ERR;
                },
            }
        }
    }.thunk;
}

// THE NATS LIBRARY WILL TRY TO FREE THE SIGNATURE AND ALSO THE ERROR MESSAGE, SO THEY MUST
// BE ALLOCATED WITH THE C ALLOCATOR
const SignatureHandlerCallback = fn (?*?[*:0]u8, ?*?[*]u8, ?*c_int, ?[*:0]const u8, ?*anyopaque) callconv(.C) nats_c.natsStatus;

pub const SignatureResponseOrError = union(enum) {
    signature: []u8,
    error_message: [:0]u8,
};

pub fn SignatureHandlerCallbackSignature(comptime T: type) type {
    return fn (*T, [:0]const u8) SignatureResponseOrError;
}

fn makeSignatureHandlerCallbackThunk(
    comptime T: type,
    comptime callback: *const SignatureHandlerCallbackSignature(T),
) *const SignatureHandlerCallback {
    return struct {
        fn thunk(
            err_out_raw: ?*?[*:0]u8,
            sig_out_raw: ?*?[*]u8,
            sig_len_out_raw: ?*c_int,
            nonsense: ?[*:0]const u8,
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @alignCast(@ptrCast(u)) else unreachable;
            const nonce = nonsense orelse unreachable;
            const err_out = err_out_raw orelse unreachable;
            const sig_out = sig_out_raw orelse unreachable;
            const sig_len_out = sig_len_out_raw orelse unreachable;

            switch (callback(data, std.mem.sliceTo(nonce, 0))) {
                .signature => |sig| {
                    sig_out.* = sig.ptr;
                    sig_len_out.* = @intCast(sig.len);
                    return nats_c.NATS_OK;
                },
                .error_message => |msg| {
                    err_out.* = msg.ptr;
                    return nats_c.NATS_ERR;
                },
            }
        }
    }.thunk;
}
