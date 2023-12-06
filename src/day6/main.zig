const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

const Race = struct {
    record: u64,
    time: u64,

    pub fn simulate_race(self: Race, holding_duration: u64) bool {
        var speed: u64 = holding_duration;
        var distance: u64 = 0;

        distance += speed * (self.time - holding_duration);

        return distance > self.record;
    }
};

const example_races: [3]Race = .{
    .{ .record = 9, .time = 7 },
    .{ .record = 40, .time = 15 },
    .{ .record = 200, .time = 30 },
};

const input_races: [4]Race = .{
    .{ .record = 543, .time = 59 },
    .{ .record = 1020, .time = 68 },
    .{ .record = 1664, .time = 82 },
    .{ .record = 1022, .time = 74 },
};

const twist_part_2_big_race = Race{
    .record = 543102016641022,
    .time = 59688274,
};

pub fn main() !void {
    try part1();
    try part2();
}

fn part1() !void {
    var times_record_broken_mul: u64 = 1;

    for (input_races) |race| {
        std.debug.print("Simulating race {any}\n", .{race});

        var times_record_broken: u64 = 0;

        for (0..race.time) |holding_duration| {
            if (race.simulate_race(holding_duration)) {
                times_record_broken += 1;
            }
        }

        if (times_record_broken > 0) {
            times_record_broken_mul *= times_record_broken;
        }
    }

    std.debug.print("Part 1: {d}\n", .{times_record_broken_mul});
}

fn part2() !void {
    const race = twist_part_2_big_race;

    var times_record_broken: u64 = 0;

    for (0..race.time) |holding_duration| {
        if (race.simulate_race(holding_duration)) {
            times_record_broken += 1;
        }
    }

    std.debug.print("Part 2: {d}\n", .{times_record_broken});
}
