const std = @import("std");
const ChildProcess = std.process.Child;

const LogStream = struct { eventMessage: []const u8, subsystem: []const u8, timestamp: []const u8 };

const AppEvent = struct { timeString: []const u8, service: []const u8, bundleId: []const u8, path: ?[]const u8, outcome: []const u8 };
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn emitEvent(event: AppEvent) !void {
    try stdout.print("{s},{s},\"{s}\",{s},{s}\n", .{ event.timeString, event.service, if (event.path) |path| path else "", event.bundleId, event.outcome });
}

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

        var evtObject = AppEvent{ .timeString = parsed.value.timestamp, .service = undefined, .bundleId = undefined, .path = null, .outcome = undefined };

        try stderr.print("debug {s}\n", .{parsed.value.eventMessage});
        // debug Handling access request: kTCCServiceFileProviderDomain:<private>:<private>, default_allow: 0, authValue: 1,

        if (std.mem.startsWith(u8, parsed.value.eventMessage, "Handling access request to ")) {
            var startIdx: usize = undefined;
            var endIdx: usize = undefined;

            {
                const prefix = "Handling access request to ";
                startIdx = std.mem.indexOf(u8, parsed.value.eventMessage, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ",").?;
                evtObject.service = parsed.value.eventMessage[startIdx..endIdx];
            }
            {
                const prefix = "Sub:{";
                startIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, endIdx, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, "}").?;
                var bundleId = parsed.value.eventMessage[startIdx..endIdx];

                // debug Handling access request to kTCCServiceReminders, from Sub:{/System/Library/PrivateFrameworks/AppleMediaServices.framework/Versions/A/Resources/amsaccountsd}Resp:{TCCDProcess: identifier=com.apple.amsaccountsd, pid=89859, auid=501, euid=501, binary_path=/System/Library/PrivateFrameworks/AppleMediaServices.framework/Versions/A/Resources/amsaccountsd}, ReqResult(Auth Right: Unknown (None), promptType: 1,DB Action:None, UpdateVerifierData)q
                if (std.mem.indexOf(u8, bundleId, "/") != null) {
                    const prefix2 = "{TCCDProcess: identifier=";
                    startIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, endIdx, prefix2).? + prefix2.len;
                    endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ",").?;
                    bundleId = parsed.value.eventMessage[startIdx..endIdx];
                }

                evtObject.bundleId = bundleId;
            }
            {
                const prefix = ", binary_path=";
                startIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, endIdx, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, "}").?;
                evtObject.path = parsed.value.eventMessage[startIdx..endIdx];
            }
            {
                const prefix = "Auth Right: ";
                startIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, endIdx, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ",").?;
                evtObject.outcome = parsed.value.eventMessage[startIdx..endIdx];
            }
        } else if (std.mem.startsWith(u8, parsed.value.eventMessage, "Override: ")) {
            var startIdx: usize = undefined;
            var endIdx: usize = undefined;

            {
                const prefix = "matched <";
                startIdx = std.mem.indexOf(u8, parsed.value.eventMessage, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ",").?;
                evtObject.service = parsed.value.eventMessage[startIdx..endIdx];
            }
            {
                startIdx = endIdx + 2;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ">").?;
                evtObject.bundleId = parsed.value.eventMessage[startIdx..endIdx];
            }
            {
                const prefix = "result: Auth:";
                startIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, endIdx, prefix).? + prefix.len;
                endIdx = std.mem.indexOfPos(u8, parsed.value.eventMessage, startIdx, ";").?;
                evtObject.outcome = parsed.value.eventMessage[startIdx..endIdx];
            }
        } else {
            try stderr.print("Unexpected line {s}\n", .{parsed.value.eventMessage});
            continue;
        }

        try emitEvent(evtObject);
    }
}
