const std = @import("std");

const size = 10;
var map: [size * size]u8 = [1]u8{0} ** (size * size);

const Coordinates = struct { x: i8, y: i8 };

const Size = Coordinates;

const Directions = enum(u8) { Up, Right, Down, Left };

var prng: std.rand.DefaultPrng = undefined;

var porter: u8 = 1;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("We have memory leaks.", .{});
        }
    }
    const allocator = gpa.allocator();
    var position_history = std.ArrayList(Coordinates).init(allocator);
    defer position_history.deinit();
    prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const measures: Size = .{ .x = 10, .y = 10 };
    var position = PickEntranceCoordinates(measures);
    try position_history.append(position);

    while (true) {
        const last_position = position_history.getLast();
        position = AdvancePosition(position);

        if (position.x == last_position.x and position.y == last_position.y) {
            _ = position_history.pop();
            const new_last_position = position_history.getLast();
            position = new_last_position;

            if (position_history.items.len == 1) {
                break;
            }
        } else {
            try position_history.append(position);
        }
    }

    for (map, 0..) |i, index| {
        const map_position = index + 1;
        std.debug.print("{} ", .{i});

        if (map_position % size == 0) {
            std.debug.print("\n", .{});
        }
    }
}

fn PickEntranceCoordinates(measures: Size) Coordinates {
    const rand = prng.random();

    // pick if we want X and Y entrance focus

    const value = rand.float(f32);
    const side = rand.float(f32);

    var coords: Coordinates = .{ .x = 0, .y = 0 };

    if (value > 0.5) {
        // we are on the Y axis
        if (side > 0.5) {
            // we are on the Right side of the axis
            coords.y = measures.y - 1;
        } else {
            // we are on the Left side of the axis
            coords.y = 0;
        }

        const position = rand.intRangeAtMost(i8, 0, measures.x - 1);
        coords.x = position;
    } else {
        // we are on the X axis
        if (side > 0.5) {
            // we are on the Right side of the axis
            coords.x = measures.x - 1;
        } else {
            // we are on the Left side of the axis
            coords.x = 0;
        }

        const position = rand.intRangeAtMost(i8, 0, measures.y - 1);
        coords.y = position;
    }

    SetMapValue(coords, 8);

    return coords;
}

fn AdvancePosition(coords: Coordinates) Coordinates {
    const rand = prng.random();

    var new_coords: Coordinates = undefined;

    var tries: u32 = 0;
    while (true) {
        const direction = rand.enumValue(Directions);
        new_coords = coords;

        switch (direction) {
            .Up => new_coords.y += 1,
            .Right => new_coords.x += 1,
            .Down => if (new_coords.y != 0) {
                new_coords.y -= 1;
            },
            .Left => if (new_coords.x != 0) {
                new_coords.x -= 1;
            },
        }

        if ((ValidNewPositionValid(new_coords) and ValidWalls(new_coords)) or tries == 10) {
            if (tries == 10) {
                return coords;
            }

            break;
        } else {}

        tries += 1;
    }

    porter += 1;
    SetMapValue(new_coords, 1);

    return new_coords;
}

fn GetMapValue(coords: Coordinates) u8 {
    return map[@as(usize, @intCast(coords.x + coords.y * size))];
}

fn SetMapValue(coords: Coordinates, value: u8) void {
    map[@as(usize, @intCast(coords.x + coords.y * size))] = value;
}

fn ValidCoords(coord: Coordinates) bool {
    return !(coord.x < 0 or coord.x >= size or coord.y < 0 or coord.y >= size);
}

fn ValidNewPositionValid(coord: Coordinates) bool {
    if (coord.x < 0 or coord.x >= size or coord.y < 0 or coord.y >= size) {
        return false;
    }

    return GetMapValue(coord) == 0;
}

fn ValidWalls(coord: Coordinates) bool {
    var wall_count: usize = 0;

    const up_wall: Coordinates = .{ .x = coord.x, .y = coord.y - 1 };
    const right_wall: Coordinates = .{ .x = coord.x + 1, .y = coord.y };
    const down_wall: Coordinates = .{ .x = coord.x, .y = coord.y + 1 };
    const left_wall: Coordinates = .{ .x = coord.x - 1, .y = coord.y };

    if (ValidCoords(up_wall) and GetMapValue(up_wall) != 0) {
        wall_count += 1;
    }

    if (ValidCoords(right_wall) and GetMapValue(right_wall) != 0) {
        wall_count += 1;
    }

    if (ValidCoords(down_wall) and GetMapValue(down_wall) != 0) {
        wall_count += 1;
    }

    if (ValidCoords(left_wall) and GetMapValue(left_wall) != 0) {
        wall_count += 1;
    }

    return wall_count <= 1;
}

test "simple test" {}
