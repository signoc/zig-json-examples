const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "json simple parse optionals" {
    // Allowing for json null.
    const Data = struct { id: u32, name: ?[]u8, email: ?[]u8 };
    const json_data =
        \\{ "id": 1, "name": "John Doe", "email": null}
    ;

    const parsed = try std.json.parseFromSlice(Data, std.testing.allocator, json_data, .{});
    defer parsed.deinit();
    const data = parsed.value;
    try expectEqual(data.id, 1);
    try expectEqualStrings(data.name.?, "John Doe");
    try expectEqual(data.email, null);
}

test "json optional missing fields" {
    // Default values allow for missing fields.
    const Data = struct { field1: u32 = 42, field2: ?u32 = null };
    const json_data =
        \\{}
    ;

    const parsed = try std.json.parseFromSlice(Data, std.testing.allocator, json_data, .{});
    defer parsed.deinit();
    const data = parsed.value;
    try expectEqual(data.field1, 42);
    try expectEqual(data.field2, null);
}

test "json non standard keys" {
    // field names that does not fit zig requirements for identifiers can be named with
    // the @"" syntax
    const Data = struct { @"kebab-case-key": bool, @"space delimited key": bool, @"åäö": bool };
    const json_data =
        \\{
        \\   "kebab-case-key": true,
        \\   "space delimited key": true,
        \\   "åäö": true
        \\}
    ;

    const parsed = try std.json.parseFromSlice(Data, std.testing.allocator, json_data, .{});
    defer parsed.deinit();
    const data = parsed.value;
    try expect(data.@"kebab-case-key" == true);
    try expect(data.@"space delimited key" == true);
    try expect(data.@"åäö" == true);
}

test "json arrays" {
    // Havent seen it possible to have a root-level array yet
    // which is allowed in most libs. even though its easy to
    // pack in an object structure by oneself
    const Data = struct { id: u32, name: ?[]u8, email: ?[]u8 };
    const json_data =
        \\{"root": [{ "id": 1, "name": "John Doe", "email": null},
        \\{ "id": 2, "name": "Jane Doe", "email": null},
        \\{ "id": 3, "name": "No Dough", "email": "nodough"}]}
    ;
    const DataArray = struct {
        root: []Data,
    };
    const parsed = try std.json.parseFromSlice(DataArray, std.testing.allocator, json_data, .{});
    defer parsed.deinit();
    const data = parsed.value;
    try (expect(data.root[2].id == 3));
}
