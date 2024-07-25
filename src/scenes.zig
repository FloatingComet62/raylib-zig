const std = @import("std");
const rl = @import("raylib.zig");
const rlc = rl.rlc;

fn abs(x: f32) f32 {
    if (x < 0) {
        return -x;
    }
    return x;
}

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

const Facing = enum { FRONT, BACK, SIDE };

pub fn getIdle(facing: Facing) usize {
    switch (facing) {
        .FRONT => {
            return 0;
        },
        .BACK => {
            return 1;
        },
        .SIDE => {
            return 2;
        },
    }
}
pub fn getRun(facing: Facing) usize {
    switch (facing) {
        .FRONT => {
            return 3;
        },
        .BACK => {
            return 4;
        },
        .SIDE => {
            return 5;
        },
    }
}

pub const Scene1 = struct {
    const Self = @This();

    button: rl.Button,
    text: rl.Text,
    scarfy: rl.Sprite,
    scarfy_facing: Facing,
    pub fn init(allocator: std.mem.Allocator, data: std.StringHashMap(f64)) !Self {
        const WIDTH: usize = @intFromFloat(data.get("width").?);
        const HEIGHT: usize = @intFromFloat(data.get("height").?);

        const button = rl.Button.init(
            rl.Vec(usize).init(WIDTH / 2, HEIGHT / 2),
            "Button Text",
            [4]u8{ 8, 8, 8, 8 },
        );
        const text = rl.Text.init(
            "Hello World",
            rl.Vec(usize).init(WIDTH / 2, 100),
        );

        var textures = try std.ArrayList(rl.TextureData).initCapacity(allocator, 6);
        defer textures.deinit();

        textures.appendAssumeCapacity(rl.TextureData.init("sprites/idle-front.png", 4));
        textures.appendAssumeCapacity(rl.TextureData.init("sprites/idle-back.png", 4));
        textures.appendAssumeCapacity(rl.TextureData.init("sprites/idle-side.png", 4));
        textures.appendAssumeCapacity(rl.TextureData.init("sprites/run-front.png", 4));
        textures.appendAssumeCapacity(rl.TextureData.init("sprites/run-back.png", 4));
        textures.appendAssumeCapacity(rl.TextureData.init("sprites/run-side.png", 4));

        return .{
            .button = button,
            .text = text,
            .scarfy = try rl.Sprite.init(allocator, textures.items, rlc.Vector2.init(15.0, 40.0)),
            .scarfy_facing = .FRONT,
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
        self.scarfy.deinit();
    }
    pub fn update(ptr: *anyopaque, data: std.StringHashMap(f64)) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        const frame = data.get("frame").?;
        if (self.button.shown) {
            self.button.pointer_on_hover(@ptrFromInt(@as(usize, @intFromFloat(
                data.get("make_mouse_pointer").?,
            ))));
        }
        const UP = rlc.isKeyDown(rlc.KeyboardKey.key_up) or
            rlc.isKeyDown(rlc.KeyboardKey.key_w);
        const DOWN = rlc.isKeyDown(rlc.KeyboardKey.key_down) or
            rlc.isKeyDown(rlc.KeyboardKey.key_s);
        const LEFT = rlc.isKeyDown(rlc.KeyboardKey.key_left) or
            rlc.isKeyDown(rlc.KeyboardKey.key_a);
        const RIGHT = rlc.isKeyDown(rlc.KeyboardKey.key_right) or
            rlc.isKeyDown(rlc.KeyboardKey.key_d);
        const STEP = 2;
        if (UP) {
            self.scarfy.position.y -= STEP;
            self.scarfy_facing = .BACK;
            self.scarfy.set_texture(getRun(.BACK));
        }
        if (DOWN) {
            self.scarfy.position.y += STEP;
            self.scarfy_facing = .FRONT;
            self.scarfy.set_texture(getRun(.FRONT));
        }
        if (LEFT) {
            self.scarfy.position.x -= STEP;
            self.scarfy_facing = .SIDE;
            self.scarfy.frame_rect.width = -abs(self.scarfy.frame_rect.width);
            self.scarfy.set_texture(getRun(.SIDE));
        }
        if (RIGHT) {
            self.scarfy.position.x += STEP;
            self.scarfy_facing = .SIDE;
            self.scarfy.frame_rect.width = abs(self.scarfy.frame_rect.width);
            self.scarfy.set_texture(getRun(.SIDE));
        }
        if (@mod(frame, 30.0) == 0.0) {
            self.scarfy.next_frame();
        }
        if (!(UP or DOWN or LEFT or RIGHT)) {
            self.scarfy.set_texture(getIdle(self.scarfy_facing));
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
        self.scarfy.draw(5);
    }
};
