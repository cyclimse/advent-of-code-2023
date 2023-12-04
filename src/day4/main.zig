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

const ScratchCard = struct {
    my_numbers: std.ArrayList(i32),
    winning_numbers: std.ArrayList(i32),

    // useful for part2
    instances: i32 = 1,

    pub fn deinit(self: *ScratchCard) void {
        self.my_numbers.deinit();
        self.winning_numbers.deinit();
    }

    pub fn score(self: *ScratchCard) i32 {
        var s: ?i32 = null;

        // should have used a hashset here
        for (self.my_numbers.items) |my_number| {
            for (self.winning_numbers.items) |winning_number| {
                if (my_number == winning_number) {
                    if (s == null) {
                        s = 1;
                    } else {
                        s = s.? * 2;
                    }
                }
            }
        }
        return s orelse 0;
    }

    pub fn matches(self: *ScratchCard) i32 {
        var m: i32 = 0;

        for (self.my_numbers.items) |my_number| {
            for (self.winning_numbers.items) |winning_number| {
                if (my_number == winning_number) {
                    m += 1;
                }
            }
        }
        return m;
    }
};

fn parse_line(allocator: mem.Allocator, line: []const u8) !ScratchCard {
    var scratch_card = ScratchCard{
        .my_numbers = std.ArrayList(i32).init(allocator),
        .winning_numbers = std.ArrayList(i32).init(allocator),
    };

    var header_iter = mem.splitSequence(u8, line, ":");
    _ = header_iter.next();

    var scratch_card_iter = mem.splitSequence(u8, header_iter.next().?, "|");

    try read_numbers(scratch_card_iter.next().?, &scratch_card.my_numbers);
    try read_numbers(scratch_card_iter.next().?, &scratch_card.winning_numbers);

    return scratch_card;
}

fn read_numbers(line: []const u8, array: *std.ArrayList(i32)) !void {
    var iter = mem.splitSequence(u8, line, " ");
    while (iter.next()) |number| {
        if (number.len == 0) {
            continue;
        }

        const num = try fmt.parseInt(i32, number, 10);
        try array.append(num);
    }
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

    var total_score: i32 = 0;

    for (lines.items) |line| {
        var scratch_card = try parse_line(allocator, line);
        defer scratch_card.deinit();

        // std.debug.print("Scratch Card: {any}\n", .{scratch_card});

        total_score += scratch_card.score();
    }

    std.debug.print("Total Score: {d}\n", .{total_score});
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

    var scratch_cards = std.ArrayList(ScratchCard).init(allocator);
    defer scratch_cards.deinit();

    for (lines.items) |line| {
        var scratch_card = try parse_line(allocator, line);
        try scratch_cards.append(scratch_card);
    }

    for (0..scratch_cards.items.len) |i| {
        const matches = scratch_cards.items[i].matches();

        for (i + 1..(i + 1 + @as(usize, @intCast(matches)))) |j| {
            // std.debug.print("Won {d} instance of scratch card: {d} via card {d}\n", .{ scratch_cards.items[i].instances, j+1, i+1 });

            scratch_cards.items[j].instances += scratch_cards.items[i].instances;
        }
    }

    var count_won_scratch_cards: i32 = 0;

    for (scratch_cards.items) |*scratch_card| {
        count_won_scratch_cards += scratch_card.instances;

        scratch_card.deinit();
    }

    std.debug.print("Count of won scratch cards: {d}\n", .{count_won_scratch_cards});
}
