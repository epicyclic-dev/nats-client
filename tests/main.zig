// This file is licensed under the CC0 1.0 license.
// See: https://creativecommons.org/publicdomain/zero/1.0/legalcode

comptime {
    if (@import("builtin").is_test) {
        _ = @import("./nats.zig");
        _ = @import("./connection.zig");
        _ = @import("./message.zig");
        _ = @import("./subscription.zig");
    }
}
