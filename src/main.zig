const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inputs_dir = try std.fs.cwd().openDir("inputs", .{});
    defer inputs_dir.close();

    var file = try get_file(inputs_dir, 1, 1, false);
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try day1_part1(reader.any(), allocator);
    std.debug.print("result={}", .{result});
}

fn get_file(inputs_dir: std.fs.Dir, comptime day: u8, comptime part: u8, comptime example: bool) !std.fs.File {
    const suffix = if (example) "example" else "real";
    const file_path = std.fmt.comptimePrint("day{}-part{}-{s}.txt", .{ day, part, suffix });

    const file = try inputs_dir.openFile(file_path, .{});
    return file;
}

const queue = std.PriorityDequeue(u64, void, lessThan);
fn lessThan(context: void, a: u64, b: u64) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

fn largest(comptime T: type, a: T, b: T) T {
    if (a < b) {
        return b;
    }

    return a;
}

fn smallest(comptime T: type, a: T, b: T) T {
    if (a < b) {
        return a;
    }

    return b;
}

fn day1_part1(reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    var left_numbers = queue.init(allocator, {});
    defer left_numbers.deinit();

    var right_numbers = queue.init(allocator, {});
    defer right_numbers.deinit();

    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var split = std.mem.split(u8, line, " ");
        const left_number = try std.fmt.parseInt(u64, split.first(), 10);

        var right_number: u64 = 0;
        while (split.next()) |part| {
            if (part.len == 0) {
                continue;
            }

            right_number = try std.fmt.parseInt(u64, part, 10);
        }

        try left_numbers.add(left_number);
        try right_numbers.add(right_number);
    }

    var total_distance: u64 = 0;
    while (left_numbers.removeMinOrNull()) |left| {
        const right = right_numbers.removeMin();
        const distance = largest(u64, left, right) - smallest(u64, left, right);
        total_distance += distance;
    }

    return total_distance;
}

test "day1 part1 example" {
    const allocator = std.testing.allocator;

    var inputs_dir = try std.fs.cwd().openDir("inputs", .{});
    defer inputs_dir.close();

    var file = try get_file(inputs_dir, 1, 1, true);
    defer file.close();

    const result = try day1_part1(file.reader().any(), allocator);
    try std.testing.expectEqual(11, result);
}
