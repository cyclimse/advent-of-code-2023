const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

const input = @embedFile("input.txt");
const example = @embedFile("example.txt");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();

    try part1(allocator);
    try part2(allocator);
}

const Part = struct {
    row: usize,
    number: i32,
    number_start: usize,
    number_end: usize,
};

const directions = [_][2]i32{
    .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
    .{ 0, -1 },  .{ 0, 1 },  .{ 1, -1 },
    .{ 1, 0 },   .{ 1, 1 },
};

fn find_all_parts(lines: []const []const u8, allocator: mem.Allocator) !std.ArrayList(Part) {
    var parts = std.ArrayList(Part).init(allocator);

    for (0..lines.len) |i| {
        var line = lines[i];
        var j: usize = 0;

        var number_start: ?usize = null;
        var number_is_part: bool = false;

        while (j < line.len) {
            const c = line[j];
            const is_digit = c >= '0' and c <= '9';

            if (is_digit) {
                if (number_start == null) {
                    number_start = j;
                }

                const is_adjacent = is_adjacent_to_symbol_all_directions(lines, i, j);
                number_is_part = number_is_part or is_adjacent;
            } else {
                if (number_start) |start| {
                    var number = try std.fmt.parseInt(i32, line[start..j], 10);

                    if (number_is_part) {
                        try parts.append(Part{ .row = i, .number = number, .number_start = start, .number_end = j });
                    }
                    number_start = null;
                    number_is_part = false;
                }
            }

            j += 1;
        }

        if (number_start) |start| {
            var number = try std.fmt.parseInt(i32, line[start..j], 10);

            if (number_is_part) {
                try parts.append(Part{ .row = i, .number = number, .number_start = start, .number_end = j });
            }
        }
    }

    return parts;
}

fn part1(allocator: mem.Allocator) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        try lines.append(line);
    }

    const parts = try find_all_parts(lines.items, allocator);
    defer parts.deinit();

    var sum: i32 = 0;

    for (parts.items) |part| {
        sum += part.number;
    }

    std.debug.print("Part 1: {}\n", .{sum});
}

fn part2(allocator: mem.Allocator) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        try lines.append(line);
    }

    var parts = try find_all_parts(lines.items, allocator);
    defer parts.deinit();

    var gear_ratio: i32 = 0;

    for (0..lines.items.len) |i| {
        for (0..lines.items[i].len) |j| {
            if (lines.items[i][j] != '*') {
                continue;
            }

            var gear_ratio_candidates: [2]i32 = undefined;
            var count: usize = 0;

            // Check the eight neighboring cells
            for (parts.items) |part| {
                if (part.row > i + 1) {
                    continue;
                } else if (part.row < i - 1) {
                    continue;
                }

                // std.debug.print("Checking gear at ({}, {}) against part {}...\n", .{ i, j, part.number });

                var is_adjacent = false;

                for (directions) |dir| {
                    var ni: i32 = @intCast(i);
                    ni += dir[0];
                    var nj: i32 = @intCast(j);
                    nj += dir[1];

                    if (ni >= 0 and nj >= 0 and ni < lines.items.len and nj < lines.items[i].len) {
                        if (part.row != ni) {
                            continue;
                        }

                        if (nj >= part.number_start and nj < part.number_end) {
                            is_adjacent = true;
                            break;
                        }
                    }
                }

                if (is_adjacent and count < 2) {
                    gear_ratio_candidates[count] = part.number;
                    count += 1;
                }

                if (count > 2) {
                    break;
                }
            }

            if (count == 2) {
                std.debug.print("Gear at ({}, {}) has gear ratio {}: {any}\n", .{
                    i,
                    j,
                    gear_ratio_candidates[0] * gear_ratio_candidates[1],
                    gear_ratio_candidates,
                });
                gear_ratio += gear_ratio_candidates[0] * gear_ratio_candidates[1];
            }
        }
    }

    std.debug.print("Part 2: {}\n", .{gear_ratio});
}

fn is_adjacent_to_symbol_all_directions(lines: []const []const u8, i: usize, j: usize) bool {
    if (!(lines[i][j] >= '0' and lines[i][j] <= '9')) {
        return false;
    }

    for (directions) |dir| {
        var ni: i32 = @intCast(i);
        ni += dir[0];
        var nj: i32 = @intCast(j);
        nj += dir[1];

        if (ni < 0 or nj < 0 or ni >= lines.len or nj >= lines[i].len) {
            continue;
        }

        const c = lines[@intCast(ni)][@intCast(nj)];
        const is_digit = c >= '0' and c <= '9';

        if (!is_digit and c != '.') {
            return true;
        }
    }

    return false;
}

const testing = std.testing;

test "is_adjacent_to_symbol_all_directions" {
    const lines = &[_][]const u8{
        "467..114..",
        "...*......",
    };
    const expected = &[_]bool{
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
    };

    for (0..lines[0].len) |i| {
        std.debug.print("i: {}\n", .{i});
        try testing.expect(is_adjacent_to_symbol_all_directions(lines, 0, i) == expected[i]);
    }
}
