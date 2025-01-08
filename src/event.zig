const std = @import("std");
const stdout = @import("./shared.zig").stdout;
const stderr = @import("./shared.zig").stderr;

const LogStream = @import("./main.zig").LogStream;

const AppEvent = struct { timeString: []const u8, service: []const u8, bundleId: []const u8, path: ?[]const u8, outcome: []const u8 };

pub fn emitEvent(event: AppEvent) !void {
    try stdout.print("{s},{s},\"{s}\",{s},{s}\n", .{ event.timeString, event.service, if (event.path) |path| path else "", event.bundleId, event.outcome });
}

pub fn processMessage(event: LogStream) ?AppEvent {
    var evtObject = AppEvent{ .timeString = event.timestamp, .service = undefined, .bundleId = undefined, .path = null, .outcome = undefined };

    if (std.mem.startsWith(u8, event.eventMessage, "Handling access request to ")) {
        var startIdx: usize = undefined;
        var endIdx: usize = undefined;

        {
            const prefix = "Handling access request to ";
            startIdx = std.mem.indexOf(u8, event.eventMessage, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ",").?;
            evtObject.service = event.eventMessage[startIdx..endIdx];
        }
        {
            const prefix = "Sub:{";
            startIdx = std.mem.indexOfPos(u8, event.eventMessage, endIdx, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, "}").?;
            var bundleId = event.eventMessage[startIdx..endIdx];

            // Handling access request to kTCCServiceReminders, from Sub:{/System/Library/PrivateFrameworks/AppleMediaServices.framework/Versions/A/Resources/amsaccountsd}Resp:{TCCDProcess: identifier=com.apple.amsaccountsd, pid=89859, auid=501, euid=501, binary_path=/System/Library/PrivateFrameworks/AppleMediaServices.framework/Versions/A/Resources/amsaccountsd}, ReqResult(Auth Right: Unknown (None), promptType: 1,DB Action:None, UpdateVerifierData)q
            if (std.mem.indexOf(u8, bundleId, "/") != null) {
                const prefix2 = "{TCCDProcess: identifier=";
                startIdx = std.mem.indexOfPos(u8, event.eventMessage, endIdx, prefix2).? + prefix2.len;
                endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ",").?;
                bundleId = event.eventMessage[startIdx..endIdx];
            }

            evtObject.bundleId = bundleId;
        }
        {
            const prefix = ", binary_path=";
            startIdx = std.mem.indexOfPos(u8, event.eventMessage, endIdx, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, "}").?;
            evtObject.path = event.eventMessage[startIdx..endIdx];
        }
        {
            const prefix = "Auth Right: ";
            startIdx = std.mem.indexOfPos(u8, event.eventMessage, endIdx, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ",").?;
            evtObject.outcome = event.eventMessage[startIdx..endIdx];
        }
    } else if (std.mem.startsWith(u8, event.eventMessage, "Override: ")) {
        var startIdx: usize = undefined;
        var endIdx: usize = undefined;

        {
            const prefix = "matched <";
            startIdx = std.mem.indexOf(u8, event.eventMessage, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ",").?;
            evtObject.service = event.eventMessage[startIdx..endIdx];
        }
        {
            startIdx = endIdx + 2;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ">").?;
            evtObject.bundleId = event.eventMessage[startIdx..endIdx];
        }
        {
            const prefix = "result: Auth:";
            startIdx = std.mem.indexOfPos(u8, event.eventMessage, endIdx, prefix).? + prefix.len;
            endIdx = std.mem.indexOfPos(u8, event.eventMessage, startIdx, ";").?;
            evtObject.outcome = event.eventMessage[startIdx..endIdx];
        }
    } else {
        stderr.print("Unexpected line {s}\n", .{event.eventMessage}) catch unreachable;
        return null;
    }

    return evtObject;
}
