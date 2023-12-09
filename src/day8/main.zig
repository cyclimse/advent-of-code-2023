const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

const input = @embedFile("input.txt");
const example = @embedFile("example.txt");

const Key = [3]u8;

fn keyEqual(a: Key, b: Key) bool {
    return a[0] == b[0] and a[1] == b[1] and a[2] == b[2];
}

const Node = struct {
    key: Key,
    left: Key,
    right: Key,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();

    // try part1(allocator);
    try part2(allocator);
}

const ParseError = error{
    InvalidInstruction,
    InvalidKey,
    InvalidLeft,
    InvalidRight,
};

fn parseKey(keyStr: []const u8) Key {
    var key: Key = undefined;
    var i: usize = 0;

    for (0..keyStr.len) |j| {
        const c = keyStr[j];

        // c can be uppercase letter or number
        if ((c < 'A' or c > 'Z') and (c < '0' or c > '9')) {
            continue;
        }

        key[i] = c;
        i += 1;
    }

    return key;
}

fn part1(allocator: mem.Allocator) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var instructions = iter.next() orelse {
        return error.InvalidInstruction;
    };

    var nodes = std.AutoHashMap(Key, Node).init(allocator);
    defer nodes.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var split = mem.splitSequence(u8, line, "=");

        var key = blk: {
            var keyStr = split.next() orelse {
                return error.InvalidKey;
            };
            break :blk parseKey(keyStr);
        };

        split = mem.splitSequence(u8, split.next().?, ",");

        var left = blk: {
            var leftStr = split.next() orelse {
                return error.InvalidLeft;
            };
            break :blk parseKey(leftStr);
        };

        var right = blk: {
            var rightStr = split.next() orelse {
                return error.InvalidRight;
            };
            break :blk parseKey(rightStr);
        };

        const node = Node{
            .key = key,
            .left = left,
            .right = right,
        };
        try nodes.put(key, node);
    }

    // var nodeIter = nodes.valueIterator();
    // while (nodeIter.next()) |node| {
    //     std.debug.print("Node: {s} {s} {s}\n", .{ node.key, node.left, node.right });
    // }

    const start = [3]u8{ 'A', 'A', 'A' };
    const end = [3]u8{ 'Z', 'Z', 'Z' };
    var pos = start;

    var i: usize = 0;
    var steps: usize = 0;

    while (!keyEqual(pos, end)) {
        var node = nodes.get(pos).?;

        std.debug.print("Position: {s} {s} {s}\n", .{ node.key, node.left, node.right });

        switch (instructions[i]) {
            'L' => pos = node.left,
            'R' => pos = node.right,
            else => return error.InvalidInstruction,
        }

        steps += 1;

        i += 1;
        i %= instructions.len;
    }

    std.debug.print("Steps: {d}\n", .{steps});
}

fn part2(allocator: mem.Allocator) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var instructions = iter.next() orelse {
        return error.InvalidInstruction;
    };

    var nodes = std.AutoHashMap(Key, Node).init(allocator);
    defer nodes.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var split = mem.splitSequence(u8, line, "=");

        var key = blk: {
            var keyStr = split.next() orelse {
                return error.InvalidKey;
            };
            break :blk parseKey(keyStr);
        };

        split = mem.splitSequence(u8, split.next().?, ",");

        var left = blk: {
            var leftStr = split.next() orelse {
                return error.InvalidLeft;
            };
            break :blk parseKey(leftStr);
        };

        var right = blk: {
            var rightStr = split.next() orelse {
                return error.InvalidRight;
            };
            break :blk parseKey(rightStr);
        };

        const node = Node{
            .key = key,
            .left = left,
            .right = right,
        };
        try nodes.put(key, node);
    }

    var positions = std.ArrayList(Key).init(allocator);
    defer positions.deinit();

    var keysIter = nodes.keyIterator();
    while (keysIter.next()) |key| {
        if (key[2] == 'A') {
            try positions.append(key.*);
        }
    }

    std.debug.print("Positions: {any}\n", .{positions.items});

    var steps_for_each_position = try std.ArrayList(usize).initCapacity(allocator, positions.items.len);
    defer steps_for_each_position.deinit();

    for (positions.items) |*pos| {
        var shouldContinue = true;
        var i: usize = 0;
        var steps: usize = 0;

        while (shouldContinue) {
            var node = nodes.get(pos.*).?;

            // std.debug.print("Position: {s} {s} {s}\n", .{ node.key, node.left, node.right });

            pos.* = switch (instructions[i]) {
                'L' => node.left,
                'R' => node.right,
                else => return error.InvalidInstruction,
            };

            steps += 1;

            if (pos[2] == 'Z') {
                try steps_for_each_position.append(steps);
                shouldContinue = false;
            }

            i += 1;
            i %= instructions.len;
        }
    }

    std.debug.print("Steps for each position: {any}\n", .{steps_for_each_position.items});

    var total: usize = 1;

    for (steps_for_each_position.items) |steps| {
        total = total * steps;
    }

    // this is cursed: 2 is the GCD of my input
    // I've used an online calculator to find it
    // total = LCM = product / GCD

    std.debug.print("Steps: {d}\n", .{total / 2});
}
