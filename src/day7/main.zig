const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

// lost the part1 solution, it's the same without adjusting for jokers

const input = @embedFile("input.txt");
const example = @embedFile("example.txt");

const cards_strongest_to_weakest = "AKQT98765432J";

fn indexOf(card: u8) usize {
    for (0..cards_strongest_to_weakest.len) |i| {
        if (cards_strongest_to_weakest[i] == card) {
            return i;
        }
    }
    unreachable;
}

fn compare_cards(a: u8, b: u8) bool {
    return indexOf(a) < indexOf(b);
}

const Type = enum {
    five_of_a_kind,
    four_of_a_kind,
    full_house,
    three_of_a_kind,
    two_pairs,
    one_pair,
    high_card,
};

const Hand = struct {
    cards: [5]u8,
    type: Type,
    winnings: u32,

    pub fn identify_type(self: *Hand) !void {
        var histogram = [_]u8{0} ** cards_strongest_to_weakest.len;
        var joker_count: u8 = 0;

        for (self.cards) |card| {
            if (card == 'J') {
                joker_count += 1;
                continue;
            }

            // we can't directly map the cards to indices because the cards
            // are not zero-indexed
            // we have to go throught the cards_strongest_to_weakest array
            histogram[indexOf(card)] += 1;
        }

        var max_count: u8 = 0;
        var pair_count: u8 = 0;

        for (histogram) |count| {
            if (count > max_count) {
                max_count = count;
            }
            if (count == 2) {
                pair_count += 1;
            }
        }

        self.type = switch (max_count) {
            5 => .five_of_a_kind,
            4 => .four_of_a_kind,
            3 => blk: {
                switch (pair_count) {
                    1 => break :blk .full_house,
                    0 => break :blk .three_of_a_kind,
                    else => unreachable,
                }
            },
            2 => blk: {
                switch (pair_count) {
                    2 => break :blk .two_pairs,
                    1 => break :blk .one_pair,
                    else => unreachable,
                }
            },
            else => .high_card,
        };

        self.type = switch (joker_count) {
            5 => .five_of_a_kind,
            4 => .five_of_a_kind,
            3 => blk: {
                if (pair_count == 1) {
                    break :blk .five_of_a_kind;
                } else {
                    break :blk .four_of_a_kind;
                }
            },
            2 => blk: {
                switch (self.type) {
                    .three_of_a_kind => break :blk .five_of_a_kind,
                    .one_pair => break :blk .four_of_a_kind,
                    .high_card => break :blk .three_of_a_kind,
                    else => unreachable,
                }
            },
            1 => blk: {
                switch (self.type) {
                    .four_of_a_kind => break :blk .five_of_a_kind,
                    .three_of_a_kind => break :blk .four_of_a_kind,
                    // turn one joker to make it a full house
                    .two_pairs => break :blk .full_house,
                    .one_pair => break :blk .three_of_a_kind,
                    .high_card => break :blk .one_pair,
                    else => unreachable,
                }
            },
            0 => self.type,
            else => unreachable,
        };
    }

    pub fn compare_hands(self: Hand, other: Hand) bool {
        const self_type = @intFromEnum(self.type);
        const other_type = @intFromEnum(other.type);

        if (self_type != other_type) {
            return self_type < other_type;
        }

        for (0..self.cards.len) |i| {
            const self_card = self.cards[i];
            const other_card = other.cards[i];

            if (self_card != other_card) {
                return compare_cards(self_card, other_card);
            }
        }

        return false;
    }
};

pub fn lessThanFn(context: void, lhs: Hand, rhs: Hand) bool {
    _ = context;
    return lhs.compare_hands(rhs);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    var allocator = gpa.allocator();

    try part1(allocator);
}

fn part1(allocator: mem.Allocator) !void {
    var iter = mem.splitSequence(u8, input, "\n");

    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();

    while (iter.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var splitIter = mem.splitSequence(u8, line, " ");

        const cardsFromIter = splitIter.next().?;
        var cards = [_]u8{0} ** 5;

        for (0..5) |i| {
            cards[i] = cardsFromIter[i];
        }

        const winnings = try fmt.parseInt(u32, splitIter.next().?, 10);

        var hand = Hand{
            .cards = cards,
            .type = undefined,
            .winnings = winnings,
        };
        try hand.identify_type();
        try hands.append(hand);
    }

    std.mem.sort(Hand, hands.items, {}, lessThanFn);

    for (0..hands.items.len) |i| {
        const rank: u32 = @intCast(hands.items.len - i);
        const hand = hands.items[i];
        std.debug.print("Rank {}: {} for {s}\n", .{ rank, hand.type, hand.cards });
    }

    var total_winnings: u32 = 0;

    for (0..hands.items.len) |i| {
        const rank: u32 = @intCast(hands.items.len - i);
        total_winnings += rank * hands.items[i].winnings;
    }

    std.debug.print("Total winnings: {}\n", .{total_winnings});
}

test "compare_hands" {
    var hand1 = Hand{
        .cards = [5]u8{ '2', '2', 'Q', 'A', '3' },
        .type = undefined,
        .winnings = 0,
    };
    try hand1.identify_type(); // high card

    var hand2 = Hand{
        .cards = [5]u8{ '2', '5', '9', 'K', '4' },
        .type = undefined,
        .winnings = 0,
    };
    try hand2.identify_type(); // high card, slightly better than hand1

    const result = hand1.compare_hands(hand2);
    try std.testing.expect(result == true);
}
