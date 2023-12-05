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

    // try part1(allocator);
    try part2(allocator);
}

const Mapping = struct {
    source_first: u64,
    source_last: u64,
    destination_first: u64,

    pub fn get(self: Mapping, source: u64) u64 {
        return self.destination_first + (source - self.source_first);
    }

    pub fn is_in_range(self: Mapping, source: u64) bool {
        return source >= self.source_first and source <= self.source_last;
    }
};

const CustomMap = struct {
    mappings: std.ArrayList(Mapping),

    pub fn get(self: CustomMap, key: u64) u64 {
        for (self.mappings.items) |mapping| {
            if (mapping.is_in_range(key)) {
                return mapping.get(key);
            }
        }

        // If a key is not in the map, it maps to itself
        return key;
    }

    pub fn set(self: *CustomMap, dest_range_start: u64, source_range_start: u64, range_length: u64) !void {
        try self.mappings.append(Mapping{
            .source_first = source_range_start,
            .source_last = source_range_start + range_length - 1,
            .destination_first = dest_range_start,
        });
    }
};

const Almanac = struct {
    seeds: std.ArrayList(u64),
    seed_to_soil: CustomMap,
    soil_to_fertilizer: CustomMap,
    fertilizer_to_water: CustomMap,
    water_to_light: CustomMap,
    light_to_temperature: CustomMap,
    temperature_to_humidity: CustomMap,
    humidity_to_location: CustomMap,

    pub fn seed_to_location(self: *const Almanac, seed: u64) u64 {
        const soil = self.seed_to_soil.get(seed);
        const fertilizer = self.soil_to_fertilizer.get(soil);
        const water = self.fertilizer_to_water.get(fertilizer);
        const light = self.water_to_light.get(water);
        const temperature = self.light_to_temperature.get(light);
        const humidity = self.temperature_to_humidity.get(temperature);
        const location = self.humidity_to_location.get(humidity);

        return location;
    }

    pub fn deinit(self: *Almanac) void {
        self.seeds.deinit();
        self.seed_to_soil.mappings.deinit();
        self.soil_to_fertilizer.mappings.deinit();
        self.fertilizer_to_water.mappings.deinit();
        self.water_to_light.mappings.deinit();
        self.light_to_temperature.mappings.deinit();
        self.temperature_to_humidity.mappings.deinit();
        self.humidity_to_location.mappings.deinit();
    }
};

fn parse_almanac(lines: [][]const u8, allocator: std.mem.Allocator) !Almanac {
    var almanac = Almanac{
        .seeds = std.ArrayList(u64).init(allocator),
        .seed_to_soil = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .soil_to_fertilizer = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .fertilizer_to_water = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .water_to_light = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .light_to_temperature = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .temperature_to_humidity = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
        .humidity_to_location = CustomMap{ .mappings = std.ArrayList(Mapping).init(allocator) },
    };

    var first_line = lines[0];
    var iter = std.mem.splitSequence(u8, first_line, ":");
    _ = iter.next();
    try read_numbers(iter.next().?, &almanac.seeds);

    var index: u8 = 0; // changes when we meet a ":"

    for (lines[1..]) |line| {
        if (line[line.len - 1] == ':') {
            index += 1;
            continue;
        }

        var numbers = try read_3_numbers(line);
        std.debug.print("Numbers: {any}\n", .{numbers});

        // this will be slightly disgusting
        switch (index) {
            0 => {},
            1 => try almanac.seed_to_soil.set(numbers[0], numbers[1], numbers[2]),
            2 => try almanac.soil_to_fertilizer.set(numbers[0], numbers[1], numbers[2]),
            3 => try almanac.fertilizer_to_water.set(numbers[0], numbers[1], numbers[2]),
            4 => try almanac.water_to_light.set(numbers[0], numbers[1], numbers[2]),
            5 => try almanac.light_to_temperature.set(numbers[0], numbers[1], numbers[2]),
            6 => try almanac.temperature_to_humidity.set(numbers[0], numbers[1], numbers[2]),
            7 => try almanac.humidity_to_location.set(numbers[0], numbers[1], numbers[2]),
            else => unreachable,
        }
    }

    return almanac;
}

fn read_numbers(line: []const u8, array: *std.ArrayList(u64)) !void {
    var iter = mem.splitSequence(u8, line, " ");
    while (iter.next()) |number| {
        if (number.len == 0) {
            continue;
        }

        const num = try fmt.parseInt(u64, number, 10);
        try array.append(num);
    }
}

fn read_3_numbers(line: []const u8) ![3]u64 {
    var numbers: [3]u64 = undefined;
    var iter = mem.splitSequence(u8, line, " ");

    for (&numbers) |*number| {
        if (iter.next()) |num| {
            if (num.len == 0) {
                continue;
            }

            number.* = try fmt.parseInt(u64, num, 10);
        } else {
            break;
        }
    }

    return numbers;
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

    var almanac = try parse_almanac(lines.items, allocator);
    defer almanac.deinit();

    std.debug.assert(almanac.seeds.items.len >= 1);
    std.debug.print("Seeds: {any}\n", .{almanac.seeds});

    var minimum_location: u64 = std.math.maxInt(u64);

    for (almanac.seeds.items) |seed| {
        const location = almanac.seed_to_location(seed);
        if (location < minimum_location) {
            minimum_location = location;
        }
    }

    std.debug.print("Minimum location: {any}\n", .{minimum_location});
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

    var almanac = try parse_almanac(lines.items, allocator);
    defer almanac.deinit();

    std.debug.assert(almanac.seeds.items.len >= 1);
    std.debug.print("Seeds: {any}\n", .{almanac.seeds});

    var minimum_location: u64 = std.math.maxInt(u64);
    var minimum_location_seed: u64 = 0;
    var minimmum_location_range_first: u64 = 0;
    var minimum_location_range_last: u64 = 0;

    const sampling_rate = 1000;

    // now seeds are in pair and represent a range
    for (0..almanac.seeds.items.len / 2) |i| {
        const first = almanac.seeds.items[i * 2 + 0];
        const range_length = almanac.seeds.items[i * 2 + 1];
        const last = first + range_length - 1;

        for (first..last) |seed| {
            if (seed % sampling_rate != 0) {
                continue;
            }

            const location = almanac.seed_to_location(seed);
            if (location < minimum_location) {
                minimum_location = location;
                minimum_location_seed = seed;
                minimmum_location_range_first = first;
                minimum_location_range_last = last;
            }
        }
    }

    std.debug.print("Minimum location with sampling_rate of {d}: {d}\n", .{ sampling_rate, minimum_location });

    for (minimum_location_seed - sampling_rate..minimum_location_seed + sampling_rate) |seed| {
        const location = almanac.seed_to_location(seed);
        if (location < minimum_location) {
            minimum_location = location;
            minimum_location_seed = seed;
        }
    }

    std.debug.print("Minimum location: {d}\n", .{minimum_location});
}
