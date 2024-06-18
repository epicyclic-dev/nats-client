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

const nats_c = @import("./nats_c.zig").nats_c;

// pub const AllocError = Error || std.mem.Allocator.Error;

pub const ErrorInfo = struct {
    code: ?Error,
    desc: [:0]const u8,
};

pub fn getLastError() ErrorInfo {
    var status: c_uint = 0;
    const desc = nats_c.nats_GetLastError(&status);

    return .{
        .code = Status.fromInt(status).toError(),
        .desc = std.mem.sliceTo(desc, 0),
    };
}

pub fn getLastErrorStack(buffer: *[]u8) Error!void {
    const status = Status.fromInt(nats_c.nats_GetLastErrorStack(buffer.ptr, buffer.len));
    return status.raise();
}

// NATS_EXTERN void nats_PrintLastErrorStack(FILE *file);

pub const Status = enum(c_int) {
    okay = nats_c.NATS_OK,
    generic_error = nats_c.NATS_ERR,
    protocol_error = nats_c.NATS_PROTOCOL_ERROR,
    io_error = nats_c.NATS_IO_ERROR,
    line_too_long = nats_c.NATS_LINE_TOO_LONG,
    connection_closed = nats_c.NATS_CONNECTION_CLOSED,
    no_server = nats_c.NATS_NO_SERVER,
    stale_connection = nats_c.NATS_STALE_CONNECTION,
    secure_connection_wanted = nats_c.NATS_SECURE_CONNECTION_WANTED,
    secure_connection_required = nats_c.NATS_SECURE_CONNECTION_REQUIRED,
    connection_disconnected = nats_c.NATS_CONNECTION_DISCONNECTED,
    connection_auth_failed = nats_c.NATS_CONNECTION_AUTH_FAILED,
    not_permitted = nats_c.NATS_NOT_PERMITTED,
    not_found = nats_c.NATS_NOT_FOUND,
    address_missing = nats_c.NATS_ADDRESS_MISSING,
    invalid_subject = nats_c.NATS_INVALID_SUBJECT,
    invalid_arg = nats_c.NATS_INVALID_ARG,
    invalid_subscription = nats_c.NATS_INVALID_SUBSCRIPTION,
    invalid_timeout = nats_c.NATS_INVALID_TIMEOUT,
    illegal_state = nats_c.NATS_ILLEGAL_STATE,
    slow_consumer = nats_c.NATS_SLOW_CONSUMER,
    max_payload = nats_c.NATS_MAX_PAYLOAD,
    max_delivered_msgs = nats_c.NATS_MAX_DELIVERED_MSGS,
    insufficient_buffer = nats_c.NATS_INSUFFICIENT_BUFFER,
    no_memory = nats_c.NATS_NO_MEMORY,
    sys_error = nats_c.NATS_SYS_ERROR,
    timeout = nats_c.NATS_TIMEOUT,
    failed_to_initialize = nats_c.NATS_FAILED_TO_INITIALIZE,
    not_initialized = nats_c.NATS_NOT_INITIALIZED,
    ssl_error = nats_c.NATS_SSL_ERROR,
    no_server_support = nats_c.NATS_NO_SERVER_SUPPORT,
    not_yet_connected = nats_c.NATS_NOT_YET_CONNECTED,
    draining = nats_c.NATS_DRAINING,
    invalid_queue_name = nats_c.NATS_INVALID_QUEUE_NAME,
    no_responders = nats_c.NATS_NO_RESPONDERS,
    mismatch = nats_c.NATS_MISMATCH,
    missed_heartbeat = nats_c.NATS_MISSED_HEARTBEAT,
    _,

    // this is a weird quirk of translate-c. All the enum members are translated as independent
    // constants of type c_int, but the enum type itself is translated as c_uint.
    pub fn fromInt(int: c_uint) Status {
        return @enumFromInt(int);
    }

    pub fn toInt(self: Status) c_uint {
        return @intFromEnum(self);
    }

    pub fn description(self: Status) [:0]const u8 {
        return std.mem.sliceTo(nats_c.natsStatus_GetText(self), 0);
    }

    pub fn raise(self: Status) Error!void {
        return switch (self) {
            .okay => void{},
            .generic_error => Error.GenericError,
            .protocol_error => Error.ProtocolError,
            .io_error => Error.IoError,
            .line_too_long => Error.LineTooLong,
            .connection_closed => Error.ConnectionClosed,
            .no_server => Error.NoServer,
            .stale_connection => Error.StaleConnection,
            .secure_connection_wanted => Error.SecureConnectionWanted,
            .secure_connection_required => Error.SecureConnectionRequired,
            .connection_disconnected => Error.ConnectionDisconnected,
            .connection_auth_failed => Error.ConnectionAuthFailed,
            .not_permitted => Error.NotPermitted,
            .not_found => Error.NotFound,
            .address_missing => Error.AddressMissing,
            .invalid_subject => Error.InvalidSubject,
            .invalid_arg => Error.InvalidArg,
            .invalid_subscription => Error.InvalidSubscription,
            .invalid_timeout => Error.InvalidTimeout,
            .illegal_state => Error.IllegalState,
            .slow_consumer => Error.SlowConsumer,
            .max_payload => Error.MaxPayload,
            .max_delivered_msgs => Error.MaxDeliveredMsgs,
            .insufficient_buffer => Error.InsufficientBuffer,
            .no_memory => Error.NoMemory,
            .sys_error => Error.SysError,
            .timeout => Error.Timeout,
            .failed_to_initialize => Error.FailedToInitialize,
            .not_initialized => Error.NotInitialized,
            .ssl_error => Error.SslError,
            .no_server_support => Error.NoServerSupport,
            .not_yet_connected => Error.NotYetConnected,
            .draining => Error.Draining,
            .invalid_queue_name => Error.InvalidQueueName,
            .no_responders => Error.NoResponders,
            .mismatch => Error.Mismatch,
            .missed_heartbeat => Error.MissedHeartbeat,
            _ => Error.UnknownError,
        };
    }

    pub fn toError(self: Status) ?Error {
        return switch (self) {
            .okay => null,
            .generic_error => Error.GenericError,
            .protocol_error => Error.ProtocolError,
            .io_error => Error.IoError,
            .line_too_long => Error.LineTooLong,
            .connection_closed => Error.ConnectionClosed,
            .no_server => Error.NoServer,
            .stale_connection => Error.StaleConnection,
            .secure_connection_wanted => Error.SecureConnectionWanted,
            .secure_connection_required => Error.SecureConnectionRequired,
            .connection_disconnected => Error.ConnectionDisconnected,
            .connection_auth_failed => Error.ConnectionAuthFailed,
            .not_permitted => Error.NotPermitted,
            .not_found => Error.NotFound,
            .address_missing => Error.AddressMissing,
            .invalid_subject => Error.InvalidSubject,
            .invalid_arg => Error.InvalidArg,
            .invalid_subscription => Error.InvalidSubscription,
            .invalid_timeout => Error.InvalidTimeout,
            .illegal_state => Error.IllegalState,
            .slow_consumer => Error.SlowConsumer,
            .max_payload => Error.MaxPayload,
            .max_delivered_msgs => Error.MaxDeliveredMsgs,
            .insufficient_buffer => Error.InsufficientBuffer,
            .no_memory => Error.NoMemory,
            .sys_error => Error.SysError,
            .timeout => Error.Timeout,
            .failed_to_initialize => Error.FailedToInitialize,
            .not_initialized => Error.NotInitialized,
            .ssl_error => Error.SslError,
            .no_server_support => Error.NoServerSupport,
            .not_yet_connected => Error.NotYetConnected,
            .draining => Error.Draining,
            .invalid_queue_name => Error.InvalidQueueName,
            .no_responders => Error.NoResponders,
            .mismatch => Error.Mismatch,
            .missed_heartbeat => Error.MissedHeartbeat,
            _ => Error.UnknownError,
        };
    }

    pub fn fromError(err: ?anyerror) Status {
        return if (err) |e|
            switch (e) {
                Error.ProtocolError => .protocol_error,
                Error.IoError => .io_error,
                Error.LineTooLong => .line_too_long,
                Error.ConnectionClosed => .connection_closed,
                Error.NoServer => .no_server,
                Error.StaleConnection => .stale_connection,
                Error.SecureConnectionWanted => .secure_connection_wanted,
                Error.SecureConnectionRequired => .secure_connection_required,
                Error.ConnectionDisconnected => .connection_disconnected,
                Error.ConnectionAuthFailed => .connection_auth_failed,
                Error.NotPermitted => .not_permitted,
                Error.NotFound => .not_found,
                Error.AddressMissing => .address_missing,
                Error.InvalidSubject => .invalid_subject,
                Error.InvalidArg => .invalid_arg,
                Error.InvalidSubscription => .invalid_subscription,
                Error.InvalidTimeout => .invalid_timeout,
                Error.IllegalState => .illegal_state,
                Error.SlowConsumer => .slow_consumer,
                Error.MaxPayload => .max_payload,
                Error.MaxDeliveredMsgs => .max_delivered_msgs,
                Error.InsufficientBuffer => .insufficient_buffer,
                Error.NoMemory => .no_memory,
                Error.SysError => .sys_error,
                Error.Timeout => .timeout,
                Error.FailedToInitialize => .failed_to_initialize,
                Error.NotInitialized => .not_initialized,
                Error.SslError => .ssl_error,
                Error.NoServerSupport => .no_server_support,
                Error.NotYetConnected => .not_yet_connected,
                Error.Draining => .draining,
                Error.InvalidQueueName => .invalid_queue_name,
                Error.NoResponders => .no_responders,
                Error.Mismatch => .mismatch,
                Error.MissedHeartbeat => .missed_heartbeat,
                else => .generic_error,
            }
        else
            .okay;
    }
};

pub const Error = error{
    /// Generic error
    GenericError,
    /// Error when parsing a protocol message, or not getting the expected message.
    ProtocolError,
    /// IO Error (network communication).
    IoError,
    /// The protocol message read from the socket does not fit in the read buffer.
    LineTooLong,

    /// Operation on this connection failed because the connection is closed.
    ConnectionClosed,
    /// Unable to connect, the server could not be reached or is not running.
    NoServer,
    /// The server closed our connection because it did not receive PINGs at the expected interval.
    StaleConnection,
    /// The client is configured to use TLS, but the server is not.
    SecureConnectionWanted,
    /// The server expects a TLS connection.
    SecureConnectionRequired,
    /// The connection was disconnected. Depending on the configuration, the connection may reconnect.
    ConnectionDisconnected,

    /// The connection failed due to authentication error.
    ConnectionAuthFailed,
    /// The action is not permitted.
    NotPermitted,
    /// An action could not complete because something was not found. So far, this is an internal error.
    NotFound,

    /// Incorrect URL. For instance no host specified in the URL.
    AddressMissing,

    /// Invalid subject, for instance NULL or empty string.
    InvalidSubject,
    /// An invalid argument is passed to a function. For instance passing NULL to an API that does not accept this value.
    InvalidArg,
    /// The call to a subscription function fails because the subscription has previously been closed.
    InvalidSubscription,
    /// Timeout must be positive numbers.
    InvalidTimeout,

    /// An unexpected state, for instance calling natsSubscription_NextMsg on an asynchronous subscriber.
    IllegalState,

    /// The maximum number of messages waiting to be delivered has been reached. Messages are dropped.
    SlowConsumer,

    /// Attempt to send a payload larger than the maximum allowed by the NATS Server.
    MaxPayload,
    /// Attempt to receive more messages than allowed, for instance because of #natsSubscription_AutoUnsubscribe().
    MaxDeliveredMsgs,

    /// A buffer is not large enough to accommodate the data.
    InsufficientBuffer,

    /// An operation could not complete because of insufficient memory.
    NoMemory,

    /// Some system function returned an error.
    SysError,

    /// An operation timed-out. For instance #natsSubscription_NextMsg().
    Timeout,

    /// The library failed to initialize.
    FailedToInitialize,
    /// The library is not yet initialized.
    NotInitialized,

    /// An SSL error occurred when trying to establish a connection.
    SslError,

    /// The server does not support this action.
    NoServerSupport,

    /// A connection could not be immediately established and #natsOptions_SetRetryOnFailedConnect() specified a connected callback. The connect is retried asynchronously.
    NotYetConnected,

    /// A connection and/or subscription entered the draining mode. Some operations will fail when in that mode.
    Draining,

    /// An invalid queue name was passed when creating a queue subscription.
    InvalidQueueName,

    /// No responders were running when the server received the request.
    NoResponders,

    /// For JetStream subscriptions, it means that a consumer sequence mismatch was discovered.
    Mismatch,
    /// For JetStream subscriptions, it means that the library detected that server heartbeats have been missed.
    MissedHeartbeat,

    /// The C API has returned an error that the zig layer does not know about.
    UnknownError,
};
