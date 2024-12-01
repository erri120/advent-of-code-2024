const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inputs_dir = try std.fs.cwd().openDir("inputs", .{});
    defer inputs_dir.close();

    var file = try get_file(inputs_dir, 1, 2, false);
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try day1_part2(reader.any(), allocator);
    std.debug.print("result={}", .{result});
}

fn get_file(inputs_dir: std.fs.Dir, comptime day: u8, comptime part: u8, comptime example: bool) !std.fs.File {
    const suffix = if (example) "example" else "real";
    const file_path = std.fmt.comptimePrint("day{}-part{}-{s}.txt", .{ day, part, suffix });

    const file = try inputs_dir.openFile(file_path, .{});
    return file;
}

fn lessThan(context: void, a: u64, b: u64) std.math.Order {
    _ = context;
    return std.math.order(a, b);
}

fn day1_part1(reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    const queue = std.PriorityDequeue(u64, void, lessThan);
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
        const distance = @max(left, right) - @min(left, right);
        total_distance += distance;
    }

    return total_distance;
}

fn day1_part2(reader: std.io.AnyReader, allocator: std.mem.Allocator) !u64 {
    var left_counts = std.AutoHashMap(u64, u64).init(allocator);
    defer left_counts.deinit();

    var right_counts = std.AutoHashMap(u64, u64).init(allocator);
    defer right_counts.deinit();

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

        const left_entry = try left_counts.getOrPut(left_number);
        if (!left_entry.found_existing) {
            left_entry.value_ptr.* = 1;
        } else {
            left_entry.value_ptr.* += 1;
        }

        const right_entry = try right_counts.getOrPut(right_number);
        if (!right_entry.found_existing) {
            right_entry.value_ptr.* = 1;
        } else {
            right_entry.value_ptr.* += 1;
        }
    }

    var similarity_score: u64 = 0;
    var iterator = left_counts.iterator();
    while (iterator.next()) |left_kv| {
        const left_number = left_kv.key_ptr.*;
        const right_count = right_counts.get(left_number) orelse 0;
        similarity_score += left_number * right_count * left_kv.value_ptr.*;
    }

    return similarity_score;
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

test "day1 part2 example" {
    const allocator = std.testing.allocator;

    var inputs_dir = try std.fs.cwd().openDir("inputs", .{});
    defer inputs_dir.close();

    var file = try get_file(inputs_dir, 1, 2, true);
    defer file.close();

    const result = try day1_part2(file.reader().any(), allocator);
    try std.testing.expectEqual(31, result);
}
