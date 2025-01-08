const std = @import("std");
const ChildProcess = std.process.Child;
const clap = @import("clap");
const stdout = @import("./shared.zig").stdout;
const stderr = @import("./shared.zig").stderr;
const Event = @import("./event.zig");

pub const LogStream = struct { eventMessage: []const u8, subsystem: []const u8, timestamp: []const u8 };

const commandLineArguments = clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\
    \\-s, --includeService <str>...  Include only specific services. Cannot be used with excludeService
    \\-S, --excludeService <str>...  Exclude specific services. Cannot be used with includeService
    \\
    \\-p, --includePath <str>...     Include only specific executable paths. Cannot be used with excludePath
    \\-P, --excludePath <str>...     Exclude specific executable paths. Cannot be used with includePath
    \\
    \\-b, --includeBundle <str>...   Include only specific bundle IDs. Cannot be used with excludeBundle
    \\-B, --excludeBundle <str>...   Exclude specific bundle IDs. Cannot be used with includeBundle
    \\
);

pub fn main() !void {
    var allocatorBacking = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = allocatorBacking.allocator();

    var diag = clap.Diagnostic{};

    var argsParser = clap.parse(clap.Help, &commandLineArguments, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };
    defer argsParser.deinit();

    {
        if (argsParser.args.help != 0) {
            return clap.help(stderr, clap.Help, &commandLineArguments, .{});
        }

        if (argsParser.args.includeService.len > 0 and argsParser.args.excludeService.len > 0) {
            try stderr.print("Error: --includeService and --excludeService cannot be used together\n", .{});
            return;
        } else {
            if (argsParser.args.includeService.len > 0) {
                try stdout.print("Included services:", .{});
                for (argsParser.args.includeService) |service| {
                    try stdout.print(" {s}", .{service});
                }
                try stdout.print("\n", .{});
            }

            if (argsParser.args.excludeService.len > 0) {
                try stdout.print("Excluded services:", .{});
                for (argsParser.args.excludeService) |service| {
                    try stdout.print(" {s}", .{service});
                }
                try stdout.print("\n", .{});
            }
        }

        if (argsParser.args.includePath.len > 0 and argsParser.args.excludePath.len > 0) {
            try stderr.print("Error: --includePath and --excludePath cannot be used together\n", .{});
            return;
        } else {
            if (argsParser.args.includePath.len > 0) {
                try stdout.print("Included paths:", .{});
                for (argsParser.args.includePath) |path| {
                    try stdout.print(" {s}", .{path});
                }
                try stdout.print("\n", .{});
            }

            if (argsParser.args.excludePath.len > 0) {
                try stdout.print("Excluded paths:", .{});
                for (argsParser.args.excludePath) |path| {
                    try stdout.print(" {s}", .{path});
                }
                try stdout.print("\n", .{});
            }
        }

        if (argsParser.args.includeBundle.len > 0 and argsParser.args.excludeBundle.len > 0) {
            try stderr.print("Error: --includeBundle and --excludeBundle cannot be used together\n", .{});
            return;
        } else {
            if (argsParser.args.includeBundle.len > 0) {
                try stdout.print("Included bundle IDs:", .{});
                for (argsParser.args.includeBundle) |bundle| {
                    try stdout.print(" {s}", .{bundle});
                }
                try stdout.print("\n", .{});
            }

            if (argsParser.args.excludeBundle.len > 0) {
                try stdout.print("Excluded bundle IDs:", .{});
                for (argsParser.args.excludeBundle) |bundle| {
                    try stdout.print(" {s}", .{bundle});
                }
                try stdout.print("\n", .{});
            }
        }
    }

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

        if (Event.processMessage(parsed.value)) |evtObject| {
            if (!shouldEmit(evtObject, argsParser)) continue;

            try Event.emitEvent(evtObject);
        }
    }
}

fn shouldEmit(evtObject: Event.AppEvent, argsParser: clap.Result(clap.Help, &commandLineArguments, clap.parsers.default)) bool {
    if (argsParser.args.includeService.len > 0) {
        var found = false;
        for (argsParser.args.includeService) |service| {
            if (std.mem.eql(u8, evtObject.service, service)) {
                found = true;
                break;
            }
        }

        if (!found) return false;
    }

    if (argsParser.args.includePath.len > 0) {
        var found = false;

        if (evtObject.path) |evtObjectPath| {
            for (argsParser.args.includePath) |path| {
                if (std.mem.eql(u8, evtObjectPath, path)) {
                    found = true;
                    break;
                }
            }
        }

        if (!found) return false;
    }

    if (argsParser.args.includeBundle.len > 0) {
        var found = false;
        for (argsParser.args.includeBundle) |bundleId| {
            if (std.mem.eql(u8, evtObject.bundleId, bundleId)) {
                found = true;
                break;
            }
        }

        if (!found) return false;
    }

    if (argsParser.args.excludeService.len > 0) {
        for (argsParser.args.excludeService) |service| {
            if (std.mem.eql(u8, evtObject.service, service)) {
                return false;
            }
        }
    }

    if (argsParser.args.excludePath.len > 0) {
        if (evtObject.path) |evtObjectPath| {
            for (argsParser.args.excludePath) |path| {
                if (std.mem.eql(u8, evtObjectPath, path)) {
                    return false;
                }
            }
        }
    }

    if (argsParser.args.excludeBundle.len > 0) {
        for (argsParser.args.excludeBundle) |bundleId| {
            if (std.mem.eql(u8, evtObject.bundleId, bundleId)) {
                return false;
            }
        }
    }

    return true;
}
