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

    // needs a simple thunk. same signature as the subscription completion callback and
    // could use the same thunk. Perhaps I should move the thunks into a common module?

    // typedef const char* (*natsTokenHandler)(void *closure);
    // NATS_EXTERN natsStatus natsOptions_SetTokenHandler(natsOptions *opts, natsTokenHandler tokenCb, void *closure);
    // pub fn setTokenHandler(self: *ConnectionOptions, comptime T: type, callback: Thunked, userdata: T) Error!void

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

    // needs a callback thunk
    // typedef int64_t (*natsCustomReconnectDelayHandler)(natsConnection *nc, int attempts, void *closure);
    // NATS_EXTERN natsStatus natsOptions_SetCustomReconnectDelay(natsOptions *opts, natsCustomReconnectDelayHandler cb, void *closure);
    // pub fn setCustomReconnectDelay(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetMaxReconnect(@ptrCast(self), max),
    //     ).raise();
    // }

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

    // needs a callback thunk
    // typedef void (*natsErrHandler)(
    //     natsConnection *nc, natsSubscription *subscription, natsStatus err,
    //     void *closure);
    // NATS_EXTERN natsStatus natsOptions_SetErrorHandler(natsOptions *opts, natsErrHandler errHandler, void *closure);
    // pub fn setErrorHandler(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetErrorHandler(@ptrCast(self), max),
    //     ).raise();
    // }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetClosedCB(natsOptions *opts, natsConnectionHandler closedCb, void *closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);
    // pub fn setClosedCallback(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetClosedCB(@ptrCast(self), max),
    //     ).raise();
    // }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetDisconnectedCB(natsOptions *opts, natsConnectionHandler disconnectedCb, void *closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);
    // pub fn setDisconnectedCallback(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetDisconnectedCB(@ptrCast(self), max),
    //     ).raise();
    // }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetReconnectedCB(natsOptions *opts, natsConnectionHandler reconnectedCb, void *closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);
    // pub fn setReconnectedCallback(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetReconnectedCB(@ptrCast(self), max),
    //     ).raise();
    // }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetDiscoveredServersCB(natsOptions *opts, natsConnectionHandler discoveredServersCb, void *closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);
    // pub fn setDiscoveredServersCallback(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetDiscoveredServersCB(@ptrCast(self), max),
    //     ).raise();
    // }

    pub fn ignoreDiscoveredServers(self: *ConnectionOptions, ignore: bool) Error!void {
        return Status.fromInt(
            nats_c.natsOptions_SetIgnoreDiscoveredServers(@ptrCast(self), ignore),
        ).raise();
    }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetLameDuckModeCB(natsOptions *opts, natsConnectionHandler lameDuckCb, void *closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);
    // pub fn setLameDuckModeCallback(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetLameDuckModeCB(@ptrCast(self), max),
    //     ).raise();
    // }

    // needs a callback thunk
    // NATS_EXTERN natsStatus natsOptions_SetEventLoop(natsOptions *opts, void *loop, natsEvLoop_Attach attachCb, natsEvLoop_ReadAddRemove readCb, natsEvLoop_WriteAddRemove writeCb, natsEvLoop_Detach detachCb);
    // typedef natsStatus (*natsEvLoop_Attach)(
    //     void            **userData,
    //     void            *loop,
    //     natsConnection  *nc,
    //     natsSock        socket);
    // pub fn setEventLoop(self: *ConnectionOptions, max: c_int) Error!void {
    //     return Status.fromInt(
    //         nats_c.natsOptions_SetEventLoop(@ptrCast(self), max),
    //     ).raise();
    // }

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

    // thunkem
    // NATS_EXTERN natsStatus natsOptions_SetRetryOnFailedConnect(natsOptions *opts, bool retry, natsConnectionHandler connectedCb, void* closure);
    // typedef void (*natsConnectionHandler)(
    //     natsConnection  *nc, void *closure);

    // 2 thunk 2 furious
    // NATS_EXTERN natsStatus natsOptions_SetUserCredentialsCallbacks(natsOptions *opts, natsUserJWTHandler ujwtCB, void *ujwtClosure, natsSignatureHandler sigCB, void *sigClosure);
    // typedef natsStatus (*natsUserJWTHandler)(
    //     char            **userJWT,
    //     char            **customErrTxt,
    //     void            *closure);
    // typedef natsStatus (*natsSignatureHandler)(
    //     char            **customErrTxt,
    //     unsigned char   **signature,
    //     int             *signatureLength,
    //     const char      *nonce,
    //     void            *closure);

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

    // thunk
    // NATS_EXTERN natsStatus natsOptions_SetNKey(natsOptions *opts, const char *pubKey, natsSignatureHandler sigCB, void *sigClosure);
    // typedef natsStatus (*natsSignatureHandler)(
    //     char            **customErrTxt,
    //     unsigned char   **signature,
    //     int             *signatureLength,
    //     const char      *nonce,
    //     void            *closure);

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
