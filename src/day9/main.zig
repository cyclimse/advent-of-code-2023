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

    try part1(allocator, false);
    try part1(allocator, true);
}

fn part1(allocator: std.mem.Allocator, reverse: bool) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var sum: i128 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        var arena_allocator = arena.allocator();

        var array = std.ArrayList(i128).init(arena_allocator);

        try read_numbers(line, &array);

        var differences = std.ArrayList(std.ArrayList(i128)).init(arena_allocator);

        // part2: reverse the array
        if (reverse) {
            std.mem.reverse(i128, array.items);
        }

        try differences.append(array);

        var all_zeros = false;

        while (!all_zeros) {
            all_zeros = true;

            var difference = std.ArrayList(i128).init(arena_allocator);
            var last_array = differences.getLast();

            for (last_array.items[0 .. last_array.items.len - 1], last_array.items[1..last_array.items.len]) |i, j| {
                var diff = j - i;
                if (diff != 0) {
                    all_zeros = false;
                }
                try difference.append(diff);
            }

            if (all_zeros) {
                break;
            }

            try differences.append(difference);
        }

        // predict the value of the last numbers appended
        // by using the previous differences

        for (0..differences.items.len - 1) |j| {
            const i = differences.items.len - 1 - j;
            var diffs = differences.items[i];
            var numbers = &differences.items[i - 1];

            var last_number = numbers.getLast();
            var last_diff = diffs.getLast();

            var next_number = last_number + last_diff;

            try numbers.append(next_number);
        }

        for (differences.items) |*diff| {
            std.debug.print("Difference: {any}\n", .{diff.items});
        }

        const predicted = differences.items[0].getLast();
        std.debug.print("Predicted: {d}\n", .{predicted});

        sum += predicted;
    }

    std.debug.print("Sum: {d}\n", .{sum});
}

fn read_numbers(line: []const u8, array: *std.ArrayList(i128)) !void {
    var iter = mem.splitSequence(u8, line, " ");
    while (iter.next()) |number| {
        if (number.len == 0) {
            continue;
        }

        const num = try fmt.parseInt(i128, number, 10);
        try array.append(num);
    }
}
