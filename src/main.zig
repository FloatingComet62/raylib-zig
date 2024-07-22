const std = @import("std");
const rl = @import("raylib.zig");
const rlc = rl.rl;
const scenes = @import("scenes.zig");

const WIDTH: usize = 1280;
const HEIGHT: usize = 800;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const seed: u64 = @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
    var prng = std.rand.DefaultPrng.init(seed);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator: std.mem.Allocator = gpa.allocator();

    // var arena = std.heap.ArenaAllocator.init(allocator);
    // defer arena.deinit();
    // const arena_allocator = arena.allocator();

    try stdout.print("{}\n", .{prng.random().float(f64)});

    rlc.setConfigFlags(rlc.ConfigFlags{ .vsync_hint = true });
    rlc.initWindow(WIDTH, HEIGHT, "Game");
    rlc.setWindowIcon(rlc.loadImage("favicon.png"));
    defer rlc.closeWindow();

    var data = std.StringHashMap(f64).init(allocator);
    defer data.deinit();

    try data.put("width", WIDTH);
    try data.put("height", HEIGHT);

    var scene_managers = std.ArrayList(scenes.Scene).init(allocator);
    defer scene_managers.deinit();

    var scene1 = try scenes.Scene1.init(allocator, data);
    scene1.deinit();

    try scene_managers.append(scene1.scene());

    var frame: u32 = 0;
    var active_scene: usize = 0;
    var make_mouse_pointer = false;

    while (!rlc.windowShouldClose()) {
        frame += 1;
        rlc.beginDrawing();
        defer rlc.endDrawing();
        rlc.clearBackground(rlc.Color.black);
        defer {
            if (make_mouse_pointer) {
                rlc.setMouseCursor(@intFromEnum(rlc.MouseCursor.mouse_cursor_pointing_hand));
            } else {
                rlc.setMouseCursor(@intFromEnum(rlc.MouseCursor.mouse_cursor_default));
            }
            make_mouse_pointer = false;
        }
        try data.put("make_mouse_pointer", @floatFromInt(@intFromPtr(&make_mouse_pointer)));
        try data.put("active_scene", @floatFromInt(@intFromPtr(&active_scene)));
        try data.put("frame", @as(f64, @floatFromInt(frame)));

        var scene = scene_managers.items[active_scene];
        scene.update(data);
        scene.draw();
    }
}
