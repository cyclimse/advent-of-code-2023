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

    var iter = mem.splitSequence(u8, input, "\n");

    // var possible_games: usize = 0;
    var total_power: i32 = 0;

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var game = try parse_line(line, allocator);
        defer game.sets.deinit();

        // if (try part1_is_possible(game)) {
        //     possible_games += game.id;
        // }

        total_power += try part2_minimum_set(game);
    }

    // std.debug.print("Possible games: {}\n", .{possible_games});
    std.debug.print("Total power: {}\n", .{total_power});
}

const Game = struct {
    id: usize,
    sets: std.ArrayList(Set),
};

const Set = struct { blue: i32, green: i32, red: i32 };

fn parse_line(line: []const u8, allocator: std.mem.Allocator) !Game {
    var game = Game{ .id = 1, .sets = std.ArrayList(Set).init(allocator) };

    var gameStart: usize = 0;
    for (line) |c| {
        gameStart += 1;
        if (c == ':') {
            break;
        }
    }

    // hacky way to get the game id
    game.id = try std.fmt.parseInt(usize, line[5 .. gameStart - 1], 10);

    var iter = mem.splitSequence(u8, line[gameStart..], ";");

    while (iter.next()) |split| {
        var set = try parse_set(split);
        try game.sets.append(set);
    }

    return game;
}

const ParsingError = error{InvalidSet};

// parse_set parses a set from a line.
// a line looks like this:  3 blue, 4 red, 2 green
fn parse_set(line: []const u8) !Set {
    var iter = mem.splitSequence(u8, line, ",");

    var set = Set{ .blue = 0, .green = 0, .red = 0 };

    while (iter.next()) |split| {
        // We expect the split to be in the form of "3 blue"
        var splitIter = mem.splitSequence(u8, split, " ");

        var count: ?i32 = null;

        while (splitIter.next()) |buf| {
            if (buf.len == 0) {
                continue;
            }

            if (count) |c| {
                if (std.mem.eql(u8, buf, "blue")) {
                    set.blue = c;
                } else if (std.mem.eql(u8, buf, "green")) {
                    set.green = c;
                } else if (std.mem.eql(u8, buf, "red")) {
                    set.red = c;
                } else {
                    return ParsingError.InvalidSet;
                }
            } else {
                count = try std.fmt.parseInt(i32, buf, 10);
            }
        }
    }

    return set;
}

const testing = std.testing;

test parse_set {
    var set = try parse_set("3 blue, 4 red, 2 green");
    try std.testing.expect(set.blue == 3);
    try std.testing.expect(set.green == 2);
    try std.testing.expect(set.red == 4);

    set = try parse_set("3 blue, 4 red");
    try std.testing.expect(set.blue == 3);
    try std.testing.expect(set.green == 0);
    try std.testing.expect(set.red == 4);
}

// The Elf would first like to know which games would have been possible
// if the bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?
fn part1_is_possible(game: Game) !bool {
    for (game.sets.items) |set| {
        if (set.red > 12) {
            return false;
        }
        if (set.green > 13) {
            return false;
        }
        if (set.blue > 14) {
            return false;
        }
    }

    return true;
}

fn part2_minimum_set(game: Game) !i32 {
    var minSet = Set{ .blue = 0, .green = 0, .red = 0 };

    for (game.sets.items) |set| {
        if (set.red > minSet.red) {
            minSet.red = set.red;
        }
        if (set.green > minSet.green) {
            minSet.green = set.green;
        }
        if (set.blue > minSet.blue) {
            minSet.blue = set.blue;
        }
    }

    return minSet.red * minSet.green * minSet.blue;
}
