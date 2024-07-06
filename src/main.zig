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

// test "json optional fields" {
//     const Data = struct { field1: u32 = 42, field2: ?u32 };
//     const json_data =
//         \\{}
//     ;
//
//     const parsed = try std.json.parseFromSlice(Data, std.testing.allocator, json_data, .{});
//     defer parsed.deinit();
//     const data = parsed.value;
//     try expectEqual(data.field1, 42);
//     try expectEqual(data.field2, null);
// }

test "json non standard keys" {
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
    // std.debug.print("config.root: {any}\n", .{data.root.?});
    try (expect(data.root[2].id == 3));
}
// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
