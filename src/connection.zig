const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

const sub_ = @import("./subscription.zig");
const Subscription = sub_.Subscription;
const SubscriptionThunkCallback = sub_.SubscriptionThunkCallback;
const subscriptionMessageThunk = sub_.subscriptionMessageThunk;

const msg_ = @import("./message.zig");
const Message = msg_.Message;

const err_ = @import("./error.zig");
const Error = err_.Error;
const Status = err_.Status;

const thunk = @import("./thunk.zig");

pub const default_server_url: [:0]const u8 = nats_c.NATS_DEFAULT_URL;

pub const Connection = opaque {
    pub fn connect(options: *ConnectionOptions) Error!*Connection {
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

    pub fn publishString(
        self: *Connection,
        subject: [:0]const u8,
        message: [:0]const u8,
    ) Error!void {
        const status = Status.fromInt(nats_c.natsConnection_PublishString(
            @ptrCast(self),
            subject,
            message,
        ));
        return status.raise();
    }

    pub fn requestString(
        self: *Connection,
        subject: [:0]const u8,
        request: [:0]const u8,
        timeout: i64,
    ) Error!*Message {
        var msg: *Message = undefined;
        const status = Status.fromInt(nats_c.natsConnection_RequestString(
            @ptrCast(&msg),
            @ptrCast(self),
            subject,
            request,
            timeout,
        ));
        return status.toError() orelse msg;
    }

    pub fn subscribe(
        self: *Connection,
        comptime T: type,
        subject: [:0]const u8,
        callback: SubscriptionThunkCallback(T),
        userdata: *T,
    ) Error!*Subscription {
        var sub: *Subscription = undefined;
        const status = Status.fromInt(nats_c.natsConnection_Subscribe(
            @ptrCast(&sub),
            @ptrCast(self),
            subject,
            subscriptionMessageThunk(T, callback),
            userdata,
        ));
        return status.toError() orelse sub;
    }
};

// NATS_EXTERN void natsConnection_ProcessReadEvent(natsConnection *nc);
// NATS_EXTERN void natsConnection_ProcessWriteEvent(natsConnection *nc);

// NATS_EXTERN bool natsConnection_IsClosed(natsConnection *nc);
// NATS_EXTERN bool natsConnection_IsReconnecting(natsConnection *nc);

// NATS_EXTERN natsConnStatus natsConnection_Status(natsConnection *nc);
// NATS_EXTERN int natsConnection_Buffered(natsConnection *nc);

// NATS_EXTERN natsStatus natsConnection_Flush(natsConnection *nc);
// NATS_EXTERN natsStatus natsConnection_FlushTimeout(natsConnection *nc, int64_t timeout);

// NATS_EXTERN int64_t natsConnection_GetMaxPayload(natsConnection *nc);
// NATS_EXTERN natsStatus natsConnection_GetStats(natsConnection *nc, natsStatistics *stats);
// NATS_EXTERN natsStatus natsConnection_GetConnectedUrl(natsConnection *nc, char *buffer, size_t bufferSize);
// NATS_EXTERN natsStatus natsConnection_GetConnectedServerId(natsConnection *nc, char *buffer, size_t bufferSize);
// NATS_EXTERN natsStatus natsConnection_GetServers(natsConnection *nc, char ***servers, int *count);
// NATS_EXTERN natsStatus natsConnection_GetDiscoveredServers(natsConnection *nc, char ***servers, int *count);
// NATS_EXTERN natsStatus natsConnection_GetLastError(natsConnection *nc, const char **lastError);
// NATS_EXTERN natsStatus natsConnection_GetClientID(natsConnection *nc, uint64_t *cid);
// NATS_EXTERN natsStatus natsConnection_Drain(natsConnection *nc);
// NATS_EXTERN natsStatus natsConnection_DrainTimeout(natsConnection *nc, int64_t timeout);
// NATS_EXTERN natsStatus natsConnection_Sign(natsConnection *nc, const unsigned char *message, int messageLen, unsigned char sig[64]);
// NATS_EXTERN natsStatus natsConnection_GetClientIP(natsConnection *nc, char **ip);
// NATS_EXTERN natsStatus natsConnection_GetRTT(natsConnection *nc, int64_t *rtt);
// NATS_EXTERN natsStatus natsConnection_HasHeaderSupport(natsConnection *nc);

// NATS_EXTERN natsStatus natsConnection_Publish(natsConnection *nc, const char *subj, const void *data, int dataLen);
// NATS_EXTERN natsStatus natsConnection_PublishString(natsConnection *nc, const char *subj, const char *str);
// NATS_EXTERN natsStatus natsConnection_PublishMsg(natsConnection *nc, natsMsg *msg);
// NATS_EXTERN natsStatus natsConnection_PublishRequest(natsConnection *nc, const char *subj, const char *reply, const void *data, int dataLen);
// NATS_EXTERN natsStatus natsConnection_PublishRequestString(natsConnection *nc, const char *subj, const char *reply, const char *str);
// NATS_EXTERN natsStatus natsConnection_Request(natsMsg **replyMsg, natsConnection *nc, const char *subj, const void *data, int dataLen, int64_t timeout);
// NATS_EXTERN natsStatus natsConnection_RequestString(natsMsg **replyMsg, natsConnection *nc, const char *subj, const char *str, int64_t timeout);
// NATS_EXTERN natsStatus natsConnection_RequestMsg(natsMsg **replyMsg, natsConnection *nc,natsMsg *requestMsg, int64_t timeout);
// NATS_EXTERN natsStatus natsConnection_Subscribe(natsSubscription **sub, natsConnection *nc, const char *subject, natsMsgHandler cb, void *cbClosure);
// NATS_EXTERN natsStatus natsConnection_SubscribeTimeout(natsSubscription **sub, natsConnection *nc, const char *subject, int64_t timeout, natsMsgHandler cb, void *cbClosure);
// NATS_EXTERN natsStatus natsConnection_SubscribeSync(natsSubscription **sub, natsConnection *nc, const char *subject);
// NATS_EXTERN natsStatus natsConnection_QueueSubscribe(natsSubscription **sub, natsConnection *nc, const char *subject, const char *queueGroup, natsMsgHandler cb, void *cbClosure);
// NATS_EXTERN natsStatus natsConnection_QueueSubscribeTimeout(natsSubscription **sub, natsConnection *nc, const char *subject, const char *queueGroup, int64_t timeout, natsMsgHandler cb, void *cbClosure);
// NATS_EXTERN natsStatus natsConnection_QueueSubscribeSync(natsSubscription **sub, natsConnection *nc, const char *subject, const char *queueGroup);

//
const ConnectionOptions = opaque {
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

    pub fn setServers(self: *ConnectionOptions, servers: [][:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetServers(
                @ptrCast(self),
                servers.ptr,
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
        comptime callback: *const thunk.SimpleCallbackSignature(T),
        userdata: T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetTokenHandler(
            @ptrCast(self),
            thunk.makeSimpleCallbackThunk(callback),
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
            nats_c.natsOptions_SetSecure(@ptrCast(self), ciphers.ptr),
        ).raise();
    }

    pub fn setCipherSuites(self: *ConnectionOptions, ciphers: [:0]const u8) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetSecure(@ptrCast(self), ciphers.ptr),
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
        userdata: T,
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
        userdata: *T,
    ) Error!void {
        return Status.fromInt(nats_c.natsOptions_SetRetryOnFailedConnect(
            @ptrCast(self),
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

const ConnectionCallback = fn (?*nats_c.natsConnection, ?*anyopaque) callconv(.C) void;

pub fn ConnectionCallbackSignature(comptime T: type) type {
    return fn (*Connection, *T) void;
}

pub fn makeConnectionCallbackThunk(
    comptime T: type,
    comptime callback: *const ConnectionCallbackSignature(T),
) *const ConnectionCallback {
    return struct {
        fn thunk(conn: ?*nats_c.natsConnection, userdata: ?*anyopaque) callconv(.C) void {
            const connection: *Connection = if (conn) |c| @ptrCast(c) else unreachable;
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;
            callback(connection, data);
        }
    }.thunk;
}

const ReconnectDelayCallback = fn (?*nats_c.natsConnection, c_int, ?*anyopaque) i64;

pub fn ReconnectDelayCallbackSignature(comptime T: type) type {
    return fn (*Connection, c_int, *T) i64;
}

pub fn makeReconnectDelayCallbackThunk(
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
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;
            return callback(connection, attempts, data);
        }
    }.thunk;
}

const ErrorHandlerCallback = fn (
    ?*nats_c.natsConnection,
    ?*nats_c.natsSubscription,
    nats_c.natsStatus,
    ?*anyopaque,
) void;

pub fn ErrorHandlerCallbackSignature(comptime T: type) type {
    return fn (*Connection, *Subscription, Status, *T) void;
}

pub fn makeErrorHandlerCallbackThunk(
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
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;

            callback(connection, subscription, Status.fromInt(status), data);
        }
    }.thunk;
}

// natsSock is an fd on non-windows and SOCKET on windows
const AttachEventLoopCallback = fn (
    *?*anyopaque,
    ?*anyopaque,
    ?*nats_c.natsConnection,
    nats_c.natsSock,
) nats_c.natsStatus;

pub fn AttachEventLoopCallbackSignature(comptime T: type, comptime L: type) type {
    return fn (*L, *Connection, c_int) anyerror!*T;
}

pub fn makeAttachEventLoopCallbackThunk(
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

const EventLoopAddRemoveCallback = fn (?*nats_c.natsConnection, c_int, ?*anyopaque) nats_c.natsStatus;

pub fn EventLoopAddRemoveCallbackSignature(comptime T: type) type {
    return fn (*Connection, c_int, *T) anyerror!void;
}

pub fn makeEventLoopAddRemoveCallbackThunk(
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
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;
            callback(connection, attempts, data) catch |err|
                return Status.fromError(err).toInt();

            return nats_c.NATS_OK;
        }
    }.thunk;
}

const EventLoopDetachCallback = fn (?*anyopaque) nats_c.natsStatus;

pub fn EventLoopDetachCallbackSignature(comptime T: type) type {
    return fn (*T) anyerror!void;
}

pub fn makeEventLoopDetachCallbackThunk(
    comptime T: type,
    comptime callback: *const EventLoopDetachCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;
            callback(data) catch |err| return Status.fromError(err).toInt();
            return nats_c.NATS_OK;
        }
    }.thunk;
}

// THE NATS LIBRARY WILL TRY TO FREE THE TOKEN AND ALSO THE ERROR MESSAGE, SO THEY MUST
// BE ALLOCATED WITH THE C ALLOCATOR
const JwtHandlerCallback = fn (*?[*:0]u8, *?[*:0]u8, ?*anyopaque) nats_c.natsStatus;

const JwtResponseOrError = union(enum) {
    jwt: [:0]u8,
    error_message: [:0]u8,
};

pub fn JwtHandlerCallbackSignature(comptime T: type) type {
    return fn (*T) JwtResponseOrError;
}

pub fn makeJwtHandlerCallbackThunk(
    comptime T: type,
    comptime callback: *const JwtHandlerCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            jwt_out: *?[*:0]u8,
            err_out: *?[*:0]u8,
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;

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
const SignatureHandlerCallback = fn (*?[*:0]u8, *?[*]u8, *c_int, [*:0]const u8, ?*anyopaque) nats_c.natsStatus;

const SignatureResponseOrError = union(enum) {
    signature: []u8,
    error_message: [:0]u8,
};

pub fn SignatureHandlerCallbackSignature(comptime T: type) type {
    return fn ([:0]const u8, *T) SignatureResponseOrError;
}

pub fn makeSignatureHandlerCallbackThunk(
    comptime T: type,
    comptime callback: *const SignatureHandlerCallbackSignature(T),
) *const ReconnectDelayCallback {
    return struct {
        fn thunk(
            err_out: *?[*:0]u8,
            sig_out: *?[*]u8,
            sig_len_out: *c_int,
            nonce: [*:0]const u8,
            userdata: ?*anyopaque,
        ) callconv(.C) nats_c.natsStatus {
            const data: *T = if (userdata) |u| @ptrCast(u) else unreachable;

            switch (callback(std.mem.sliceTo(nonce, 0), data)) {
                .signature => |sig| {
                    sig_out.* = sig.ptr;
                    sig_len_out.* = sig.len;
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
