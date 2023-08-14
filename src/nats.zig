const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

fn onMessage(
    conn: ?*nats_c.natsConnection,
    sub: ?*nats_c.natsSubscription,
    message: ?*nats_c.natsMsg,
    userdata: ?*anyopaque,
) callconv(.C) void {
    _ = sub;
    defer nats_c.natsMsg_Destroy(message);

    const msgData = nats_c.natsMsg_GetData(message)[0..@intCast(nats_c.natsMsg_GetDataLength(message))];
    std.debug.print("Received message: {s} - {s}\n", .{ nats_c.natsMsg_GetSubject(message), msgData });

    if (@as(?[*]const u8, nats_c.natsMsg_GetReply(message))) |reply| {
        _ = nats_c.natsConnection_PublishString(conn, reply, "salutations");
    }

    if (@as(?*bool, @ptrCast(userdata))) |signal| {
        signal.* = true;
    }
}

pub fn main() void {
    var conn: ?*nats_c.natsConnection = null;
    defer nats_c.natsConnection_Destroy(conn);

    if (nats_c.natsConnection_ConnectTo(&conn, nats_c.NATS_DEFAULT_URL) != nats_c.NATS_OK) {
        std.debug.print("oh no {s}\n", .{nats_c.NATS_DEFAULT_URL});
        return;
    }

    var sub: ?*nats_c.natsSubscription = null;
    defer nats_c.natsSubscription_Destroy(sub);
    var done = false;
    if (nats_c.natsConnection_Subscribe(&sub, conn, "channel", onMessage, &done) != nats_c.NATS_OK) {
        std.debug.print("whops\n", .{});
        return;
    }

    while (!done) {
        var reply: ?*nats_c.natsMsg = null;
        defer nats_c.natsMsg_Destroy(reply);

        if (nats_c.natsConnection_RequestString(&reply, conn, "channel", "whatsup", 1000) != nats_c.NATS_OK) {
            std.debug.print("geez\n", .{});
            return;
        } else if (reply) |message| {
            const msgData = nats_c.natsMsg_GetData(message)[0..@intCast(nats_c.natsMsg_GetDataLength(message))];
            std.debug.print("Got reply: {s}\n", .{msgData});
        }
    }
}

// NATS_EXTERN natsStatus nats_Open(int64_t lockSpinCount);
// NATS_EXTERN const char* nats_GetVersion(void);
// NATS_EXTERN uint32_t nats_GetVersionNumber(void);

// #define nats_CheckCompatibility() nats_CheckCompatibilityImpl(NATS_VERSION_REQUIRED_NUMBER, NATS_VERSION_NUMBER, NATS_VERSION_STRING)
// NATS_EXTERN bool nats_CheckCompatibilityImpl(uint32_t reqVerNumber, uint32_t verNumber, const char *verString);

// NATS_EXTERN int64_t nats_Now(void);
// NATS_EXTERN int64_t nats_NowInNanoSeconds(void);
// NATS_EXTERN void nats_Sleep(int64_t sleepTime);
// NATS_EXTERN const char* nats_GetLastError(natsStatus *status);
// NATS_EXTERN natsStatus nats_GetLastErrorStack(char *buffer, size_t bufLen);
// NATS_EXTERN void nats_PrintLastErrorStack(FILE *file);
// NATS_EXTERN natsStatus nats_SetMessageDeliveryPoolSize(int max);
// NATS_EXTERN void nats_ReleaseThreadMemory(void);

// NATS_EXTERN natsStatus nats_Sign(const char *encodedSeed, const char *input, unsigned char **signature, int *signatureLength);

// NATS_EXTERN void nats_Close(void);
// NATS_EXTERN natsStatus nats_CloseAndWait(int64_t timeout);

// NATS_EXTERN const char* natsStatus_GetText(natsStatus s);

// NATS_EXTERN natsStatus natsStatistics_Create(natsStatistics **newStats);
// NATS_EXTERN natsStatus natsStatistics_GetCounts(const natsStatistics *stats, uint64_t *inMsgs, uint64_t *inBytes, uint64_t *outMsgs, uint64_t *outBytes, uint64_t *reconnects);
// NATS_EXTERN void natsStatistics_Destroy(natsStatistics *stats);

// NATS_EXTERN natsStatus natsOptions_Create(natsOptions **newOpts);
// NATS_EXTERN natsStatus natsOptions_SetURL(natsOptions *opts, const char *url);
// NATS_EXTERN natsStatus natsOptions_SetServers(natsOptions *opts, const char** servers, int serversCount);
// NATS_EXTERN natsStatus natsOptions_SetUserInfo(natsOptions *opts, const char *user, const char *password);
// NATS_EXTERN natsStatus natsOptions_SetToken(natsOptions *opts, const char *token);
// NATS_EXTERN natsStatus natsOptions_SetTokenHandler(natsOptions *opts, natsTokenHandler tokenCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetNoRandomize(natsOptions *opts, bool noRandomize);
// NATS_EXTERN natsStatus natsOptions_SetTimeout(natsOptions *opts, int64_t timeout);
// NATS_EXTERN natsStatus natsOptions_SetName(natsOptions *opts, const char *name);
// NATS_EXTERN natsStatus natsOptions_SetSecure(natsOptions *opts, bool secure);
// NATS_EXTERN natsStatus natsOptions_LoadCATrustedCertificates(natsOptions *opts, const char *fileName);
// NATS_EXTERN natsStatus natsOptions_SetCATrustedCertificates(natsOptions *opts, const char *certificates);
// NATS_EXTERN natsStatus natsOptions_LoadCertificatesChain(natsOptions *opts, const char *certsFileName, const char *keyFileName);
// NATS_EXTERN natsStatus natsOptions_SetCertificatesChain(natsOptions *opts, const char *cert, const char *key);
// NATS_EXTERN natsStatus natsOptions_SetCiphers(natsOptions *opts, const char *ciphers);
// NATS_EXTERN natsStatus natsOptions_SetCipherSuites(natsOptions *opts, const char *ciphers);
// NATS_EXTERN natsStatus natsOptions_SetExpectedHostname(natsOptions *opts, const char *hostname);
// NATS_EXTERN natsStatus natsOptions_SkipServerVerification(natsOptions *opts, bool skip);
// NATS_EXTERN natsStatus natsOptions_SetVerbose(natsOptions *opts, bool verbose);
// NATS_EXTERN natsStatus natsOptions_SetPedantic(natsOptions *opts, bool pedantic);
// NATS_EXTERN natsStatus natsOptions_SetPingInterval(natsOptions *opts, int64_t interval);
// NATS_EXTERN natsStatus natsOptions_SetMaxPingsOut(natsOptions *opts, int maxPingsOut);
// NATS_EXTERN natsStatus natsOptions_SetIOBufSize(natsOptions *opts, int ioBufSize);
// NATS_EXTERN natsStatus natsOptions_SetAllowReconnect(natsOptions *opts, bool allow);
// NATS_EXTERN natsStatus natsOptions_SetMaxReconnect(natsOptions *opts, int maxReconnect);
// NATS_EXTERN natsStatus natsOptions_SetReconnectWait(natsOptions *opts, int64_t reconnectWait);
// NATS_EXTERN natsStatus natsOptions_SetReconnectJitter(natsOptions *opts, int64_t jitter, int64_t jitterTLS);
// NATS_EXTERN natsStatus natsOptions_SetCustomReconnectDelay(natsOptions *opts, natsCustomReconnectDelayHandler cb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetReconnectBufSize(natsOptions *opts, int reconnectBufSize);
// NATS_EXTERN natsStatus natsOptions_SetMaxPendingMsgs(natsOptions *opts, int maxPending);
// NATS_EXTERN natsStatus natsOptions_SetErrorHandler(natsOptions *opts, natsErrHandler errHandler, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetClosedCB(natsOptions *opts, natsConnectionHandler closedCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetDisconnectedCB(natsOptions *opts, natsConnectionHandler disconnectedCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetReconnectedCB(natsOptions *opts, natsConnectionHandler reconnectedCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetDiscoveredServersCB(natsOptions *opts, natsConnectionHandler discoveredServersCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetIgnoreDiscoveredServers(natsOptions *opts, bool ignore);
// NATS_EXTERN natsStatus natsOptions_SetLameDuckModeCB(natsOptions *opts, natsConnectionHandler lameDuckCb, void *closure);
// NATS_EXTERN natsStatus natsOptions_SetEventLoop(natsOptions *opts, void *loop, natsEvLoop_Attach attachCb, natsEvLoop_ReadAddRemove readCb, natsEvLoop_WriteAddRemove writeCb, natsEvLoop_Detach detachCb);
// NATS_EXTERN natsStatus natsOptions_UseGlobalMessageDelivery(natsOptions *opts, bool global);
// NATS_EXTERN natsStatus natsOptions_IPResolutionOrder(natsOptions *opts, int order);
// NATS_EXTERN natsStatus natsOptions_SetSendAsap(natsOptions *opts, bool sendAsap);
// NATS_EXTERN natsStatus natsOptions_UseOldRequestStyle(natsOptions *opts, bool useOldStyle);
// NATS_EXTERN natsStatus natsOptions_SetFailRequestsOnDisconnect(natsOptions *opts, bool failRequests);
// NATS_EXTERN natsStatus natsOptions_SetNoEcho(natsOptions *opts, bool noEcho);
// NATS_EXTERN natsStatus natsOptions_SetRetryOnFailedConnect(natsOptions *opts, bool retry, natsConnectionHandler connectedCb, void* closure);
// NATS_EXTERN natsStatus natsOptions_SetUserCredentialsCallbacks(natsOptions *opts, natsUserJWTHandler ujwtCB, void *ujwtClosure, natsSignatureHandler sigCB, void *sigClosure);
// NATS_EXTERN natsStatus natsOptions_SetUserCredentialsFromFiles(natsOptions *opts, const char *userOrChainedFile, const char *seedFile);
// NATS_EXTERN natsStatus natsOptions_SetUserCredentialsFromMemory(natsOptions *opts, const char *jwtAndSeedContent);
// NATS_EXTERN natsStatus natsOptions_SetNKey(natsOptions             *opts, const char              *pubKey, natsSignatureHandler    sigCB, void                    *sigClosure);
// NATS_EXTERN natsStatus natsOptions_SetNKeyFromSeed(natsOptions *opts, const char  *pubKey, const char  *seedFile);
// NATS_EXTERN natsStatus natsOptions_SetWriteDeadline(natsOptions *opts, int64_t deadline);
// NATS_EXTERN natsStatus natsOptions_DisableNoResponders(natsOptions *opts, bool disabled);
// NATS_EXTERN natsStatus natsOptions_SetCustomInboxPrefix(natsOptions *opts, const char *inboxPrefix);
// NATS_EXTERN natsStatus natsOptions_SetMessageBufferPadding(natsOptions *opts, int paddingSize);
// NATS_EXTERN void natsOptions_Destroy(natsOptions *opts);

// NATS_EXTERN natsStatus natsInbox_Create(natsInbox **newInbox);
// NATS_EXTERN void natsInbox_Destroy(natsInbox *inbox);
// NATS_EXTERN void natsMsgList_Destroy(natsMsgList *list);

// NATS_EXTERN natsStatus natsMsg_Create(natsMsg **newMsg, const char *subj, const char *reply, const char *data, int dataLen);
// NATS_EXTERN const char* natsMsg_GetSubject(const natsMsg *msg);
// NATS_EXTERN const char* natsMsg_GetReply(const natsMsg *msg);
// NATS_EXTERN const char* natsMsg_GetData(const natsMsg *msg);
// NATS_EXTERN int natsMsg_GetDataLength(const natsMsg *msg);
// NATS_EXTERN natsStatus natsMsgHeader_Set(natsMsg *msg, const char *key, const char *value);
// NATS_EXTERN natsStatus natsMsgHeader_Add(natsMsg *msg, const char *key, const char *value);
// NATS_EXTERN natsStatus natsMsgHeader_Get(natsMsg *msg, const char *key, const char **value);
// NATS_EXTERN natsStatus natsMsgHeader_Values(natsMsg *msg, const char *key, const char* **values, int *count);
// NATS_EXTERN natsStatus natsMsgHeader_Keys(natsMsg *msg, const char* **keys, int *count);
// NATS_EXTERN natsStatus natsMsgHeader_Delete(natsMsg *msg, const char *key);
// NATS_EXTERN bool natsMsg_IsNoResponders(natsMsg *msg);
// NATS_EXTERN void natsMsg_Destroy(natsMsg *msg);
// NATS_EXTERN uint64_t stanMsg_GetSequence(const stanMsg *msg);
// NATS_EXTERN int64_t stanMsg_GetTimestamp(const stanMsg *msg);
// NATS_EXTERN bool stanMsg_IsRedelivered(const stanMsg *msg);
// NATS_EXTERN const char* stanMsg_GetData(const stanMsg *msg);
// NATS_EXTERN int stanMsg_GetDataLength(const stanMsg *msg);
// NATS_EXTERN void stanMsg_Destroy(stanMsg *msg);

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

// NATS_EXTERN natsStatus natsSubscription_NoDeliveryDelay(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_NextMsg(natsMsg **nextMsg, natsSubscription *sub, int64_t timeout);
// NATS_EXTERN natsStatus natsSubscription_Unsubscribe(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_AutoUnsubscribe(natsSubscription *sub, int max);
// NATS_EXTERN natsStatus natsSubscription_QueuedMsgs(natsSubscription *sub, uint64_t *queuedMsgs);
// NATS_EXTERN int64_t natsSubscription_GetID(natsSubscription* sub);
// NATS_EXTERN const char* natsSubscription_GetSubject(natsSubscription* sub);
// NATS_EXTERN natsStatus natsSubscription_SetPendingLimits(natsSubscription *sub, int msgLimit, int bytesLimit);
// NATS_EXTERN natsStatus natsSubscription_GetPendingLimits(natsSubscription *sub, int *msgLimit, int *bytesLimit);
// NATS_EXTERN natsStatus natsSubscription_GetPending(natsSubscription *sub, int *msgs, int *bytes);
// NATS_EXTERN natsStatus natsSubscription_GetDelivered(natsSubscription *sub, int64_t *msgs);
// NATS_EXTERN natsStatus natsSubscription_GetDropped(natsSubscription *sub, int64_t *msgs);
// NATS_EXTERN natsStatus natsSubscription_GetMaxPending(natsSubscription *sub, int *msgs, int *bytes);
// NATS_EXTERN natsStatus natsSubscription_ClearMaxPending(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_GetStats(natsSubscription *sub, int *pendingMsgs, int *pendingBytes, int *maxPendingMsgs, int *maxPendingBytes, int64_t *deliveredMsgs, int64_t *droppedMsgs);
// NATS_EXTERN bool natsSubscription_IsValid(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_Drain(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_DrainTimeout(natsSubscription *sub, int64_t timeout);
// NATS_EXTERN natsStatus natsSubscription_WaitForDrainCompletion(natsSubscription *sub, int64_t timeout);
// NATS_EXTERN natsStatus natsSubscription_DrainCompletionStatus(natsSubscription *sub);
// NATS_EXTERN natsStatus natsSubscription_SetOnCompleteCB(natsSubscription *sub, natsOnCompleteCB cb, void *closure);
// NATS_EXTERN void natsSubscription_Destroy(natsSubscription *sub);

// NATS_EXTERN natsStatus natsMsg_Ack(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_AckSync(natsMsg *msg, jsOptions *opts, jsErrCode *errCode);
// NATS_EXTERN natsStatus natsMsg_Nak(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_NakWithDelay(natsMsg *msg, int64_t delay, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_InProgress(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN natsStatus natsMsg_Term(natsMsg *msg, jsOptions *opts);
// NATS_EXTERN uint64_t natsMsg_GetSequence(natsMsg *msg);
// NATS_EXTERN int64_t natsMsg_GetTime(natsMsg *msg);
