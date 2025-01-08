const std = @import("std");
const ChildProcess = std.process.Child;

const stdout = @import("./shared.zig").stdout;
const stderr = @import("./shared.zig").stderr;
const Event = @import("./event.zig");

pub const LogStream = struct { eventMessage: []const u8, subsystem: []const u8, timestamp: []const u8 };

pub fn main() !void {
    var allocatorBacking = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocatorBacking.allocator();

    const filter = "subsystem == 'com.apple.TCC' AND category == 'access' AND (eventMessage BEGINSWITH 'Override: eval: ' OR eventMessage BEGINSWITH 'Handling access request to ')";

    var proc = ChildProcess.init(&[_][]const u8{ "/usr/bin/log", "stream", "--style", "ndjson", "--info", "--predicate", filter }, allocator);
    proc.stdout_behavior = ChildProcess.StdIo.Pipe;
    proc.stderr_behavior = ChildProcess.StdIo.Ignore;
    try proc.spawn();

    // The max I've seen is around 5400 bytes
    var buffer: [8192]u8 = undefined;

    const reader = proc.stdout.?.reader();

    // Skip the first line: "Filtering the log data using ..."
    _ = try reader.readUntilDelimiter(&buffer, '\n');

    try stderr.print("Observing events...\n", .{});

    while (true) {
        const bytesRead = (try reader.readUntilDelimiter(&buffer, '\n')).len;
        const parsed = try std.json.parseFromSlice(LogStream, allocator, buffer[0..bytesRead], .{ .ignore_unknown_fields = true });
        defer parsed.deinit();

        const evtObject = Event.processMessage(parsed.value);
        if (evtObject == null) {
            continue;
        }

        try Event.emitEvent(evtObject.?);
    }
}
