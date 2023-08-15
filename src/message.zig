const std = @import("std");

pub const nats_c = @cImport({
    @cInclude("nats/nats.h");
});

pub const Message = opaque {
    pub fn destroy(self: *Message) void {
        nats_c.natsMsg_Destroy(@ptrCast(self));
    }

    pub fn getSubject(self: *Message) [:0]const u8 {
        const subject = nats_c.natsMsg_GetSubject(@ptrCast(self)) orelse unreachable;
        return std.mem.sliceTo(subject, 0);
    }

    pub fn getReply(self: *Message) ?[:0]const u8 {
        const reply = nats_c.natsMsg_GetReply(@ptrCast(self)) orelse return null;
        return std.mem.sliceTo(reply, 0);
    }

    pub fn getData(self: *Message) ?[:0]const u8 {
        const data = nats_c.natsMsg_GetData(@ptrCast(self)) orelse return null;
        return data[0..self.getDataLength() :0];
    }

    pub fn getDataLength(self: *Message) usize {
        return @intCast(nats_c.natsMsg_GetDataLength(@ptrCast(self)));
    }
};
