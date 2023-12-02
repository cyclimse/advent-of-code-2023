const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

const input = @embedFile("input.txt");

pub fn main() !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var sum: i32 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) {
            // Skip last line, which is empty
            continue;
        }

        // sum += add_to_sum_part1(line);
        sum += try add_to_sum_part2(line);
    }

    std.debug.print("Sum: {}\n", .{sum});
}

fn add_to_sum_part1(line: []const u8) !i32 {
    var first_digit_of_line: ?u8 = null;
    var last_digit_of_line: ?u8 = null;

    for (line) |c| {
        const is_digit = (c >= '0') and (c <= '9');
        if (is_digit) {
            if (first_digit_of_line == null) {
                first_digit_of_line = c - '0';
            }
            last_digit_of_line = c - '0';
        }
    }

    // Combine the two numbers
    return first_digit_of_line.? * 10 + last_digit_of_line.?;
}

const digits_to_strings = &[_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

// In this part, the digits are expressed as strings
fn add_to_sum_part2(line: []const u8) !i32 {
    var first_digit_of_line: ?u8 = null;
    var last_digit_of_line: ?u8 = null;

    // whenever a character that matches a digit is found, we bump
    // the corresponding index in this array
    var matches = [_]u8{0} ** 10;

    for (line) |c| {
        const is_digit = (c >= '0') and (c <= '9');
        if (is_digit) {
            if (first_digit_of_line == null) {
                first_digit_of_line = c - '0';
            }
            last_digit_of_line = c - '0';

            for (1..10) |i| {
                matches[i] = 0;
            }

            continue;
        }

        for (1..10) |i| {
            const digit = digits_to_strings[i - 1];

            if (c == digit[matches[i]]) {
                matches[i] += 1;
            } else {
                matches[i] = 0;

                // Edge case: twoone
                // If we have already matched the first character of the
                // digit, we need to check if the current character matches
                if (c == digit[matches[i]]) {
                    matches[i] += 1;
                }
            }

            // If we have found all the characters of a digit, we can
            // stop looking for that digit
            if (matches[i] == digit.len) {
                if (first_digit_of_line == null) {
                    first_digit_of_line = @truncate(i);
                }
                last_digit_of_line = @truncate(i);

                matches[i] = 0;
            }
        }
    }

    std.debug.print("line: {s}\n", .{line});
    std.debug.print("first: {}, last: {}\n", .{ first_digit_of_line.?, last_digit_of_line.? });

    // Combine the two numbers
    return first_digit_of_line.? * 10 + last_digit_of_line.?;
}

const testing = std.testing;
const example = @embedFile("example.txt");

test "example_part2" {
    var iter = mem.splitSequence(u8, example, "\n");

    var sum: i32 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) {
            // Skip last line, which is empty
            continue;
        }

        sum += try add_to_sum_part2(line);
    }
    try testing.expectEqual(@as(i32, 281), sum);
}
