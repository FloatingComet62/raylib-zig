const std = @import("std");
const rl = @import("raylib.zig");
const rlc = rl.rl;

pub const Scene = struct {
    const Self = @This();
    ptr: *anyopaque,

    updateFn: *const fn (ptr: *anyopaque, data: std.StringHashMap(f64)) void,
    drawFn: *const fn (ptr: *anyopaque) void,

    pub fn update(self: Self, data: std.StringHashMap(f64)) void {
        return self.updateFn(self.ptr, data);
    }
    pub fn draw(self: Self) void {
        return self.drawFn(self.ptr);
    }
};

pub const Scene1 = struct {
    const Self = @This();

    // button: rl.malloc(rl.Button),
    // text: rl.malloc(rl.Text),
    button: rl.Button,
    text: rl.Text,
    scarfy: rlc.Texture,
    pub fn init(allocator: std.mem.Allocator, data: std.StringHashMap(f64)) !Self {
        _ = allocator;
        const WIDTH: usize = @intFromFloat(data.get("width").?);
        const HEIGHT: usize = @intFromFloat(data.get("height").?);

        // const button = try rl.malloc(rl.Button).init( allocator,
        const button =
            rl.Button.init(
            rl.Vec(usize).init(WIDTH / 2, HEIGHT / 2),
            "Button Text",
            [4]u8{ 8, 8, 8, 8 },
            // ),
        );
        // const text = try rl.malloc(rl.Text).init(allocator,
        const text =
            rl.Text.init(
            "Hello World",
            rl.Vec(usize).init(WIDTH / 2, 100),
            // ),
        );

        return .{
            .button = button,
            .text = text,
            .scarfy = rlc.Texture.init("sprites/idle.png"),
        };
    }
    pub fn scene(self: *Self) Scene {
        return .{
            .ptr = self,
            .updateFn = update,
            .drawFn = draw,
        };
    }
    pub fn deinit(self: *Self) void {
        rlc.unloadTexture(self.scarfy);
    }
    pub fn update(ptr: *anyopaque, data: std.StringHashMap(f64)) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.button.shown) {
            self.button.pointer_on_hover(@ptrFromInt(@as(usize, @intFromFloat(
                data.get("make_mouse_pointer").?,
            ))));
            if (self.button.clicked()) {
                std.debug.print("fuck\n", .{});
                self.button.shown = false;
            }
        }
    }
    pub fn draw(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        if (self.button.shown) {
            rl.Button.draw(&self.button);
        }
        if (self.text.shown) {
            rl.Text.draw(&self.text);
        }
    }
};
