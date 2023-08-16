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

pub const Options = opaque {};

pub const default_server_url: [:0]const u8 = nats_c.NATS_DEFAULT_URL;

pub const Connection = opaque {
    pub fn connect(options: *Options) Error!*Connection {
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

// NATS_EXTERN natsStatus natsConnection_Connect(natsConnection **nc, natsOptions *options);
// NATS_EXTERN void natsConnection_ProcessReadEvent(natsConnection *nc);
// NATS_EXTERN void natsConnection_ProcessWriteEvent(natsConnection *nc);
// NATS_EXTERN natsStatus natsConnection_ConnectTo(natsConnection **nc, const char *urls);
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
// NATS_EXTERN void natsConnection_Close(natsConnection *nc);
// NATS_EXTERN void natsConnection_Destroy(natsConnection *nc);
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
