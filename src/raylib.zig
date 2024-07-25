const std = @import("std");
pub const rlc = @import("raylib");

fn abs(x: f32) f32 {
    if (x < 0) {
        return -x;
    }
    return x;
}

fn sign(x: f32) f32 {
    if (x == 0) {
        return 0;
    }
    if (x < 0) {
        return -1;
    }
    return 1;
}

pub const Deiniter = struct {
    const Self = @This();
    ptr: *anyopaque,
    deinitFn: *const fn (ptr: *anyopaque) void,

    pub fn deinit(self: Self) void {
        self.deinitFn(self.ptr);
    }
};

pub fn drawText(
    str: [*c]const u8,
    pos_x: usize,
    pos_y: usize,
    font_size: c_int,
    color: rlc.Color,
) void {
    const dim = rlc.measureTextEx(
        rlc.getFontDefault(),
        str,
        @floatFromInt(font_size),
        1,
    );
    const shift_x = @as(usize, @intFromFloat(dim.x / 2));
    const shift_y = @as(usize, @intFromFloat(dim.y / 2));
    rlc.drawText(str, @intCast(pos_x - shift_x), @intCast(pos_y - shift_y), font_size, color);
}

pub fn drawRectangle(
    pos_x: c_int,
    pos_y: c_int,
    width: c_int,
    height: c_int,
    color: rlc.Color,
) void {
    rlc.drawRectangle(
        pos_x - @divTrunc(width, 2),
        pos_y - @divTrunc(height, 2),
        width,
        height,
        color,
    );
}

pub const DrawMode = enum { Center, TopLeft };

pub fn Vec(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,
        a: T,
        b: T,
        w: T,
        h: T,
        pub fn init(x: T, y: T) Self {
            return .{ .x = x, .y = y, .a = x, .b = y, .w = x, .h = y };
        }
    };
}

pub fn colliding(
    comptime T: type,
    rec1_pos: Vec(T),
    rec1_dim: Vec(T),
    rec2_pos: Vec(T),
    rec2_dim: Vec(T),
) bool {
    return rec1_pos.x < rec2_pos.x + rec2_dim.x and
        rec1_pos.x + rec1_dim.x > rec2_pos.x and
        rec1_pos.y < rec2_pos.y + rec2_dim.y and
        rec1_pos.y + rec1_dim.y > rec2_pos.y;
}

pub const Drawable = struct {
    const Self = @This();
    ptr: *anyopaque,
    drawFn: *const fn (ptr: *anyopaque) void,
    shownFn: *const fn (ptr: *anyopaque) *bool,

    pub fn shown(self: Self) *bool {
        return self.shownFn(self.ptr);
    }
    pub fn draw(self: Self) void {
        return self.drawFn(self.ptr);
    }
};

const TOP = 0;
const BOTTOM = 1;
const LEFT = 2;
const RIGHT = 3;
pub const Button = struct {
    const Self = @This();
    position: Vec(usize),
    label: [*c]const u8,
    padding: [4]u8,
    font_size: c_int,
    color: rlc.Color,
    fix_factor: f32,
    shown: bool,

    pub fn init(
        position: Vec(usize),
        label: [*c]const u8,
        padding: [4]u8,
    ) Self {
        return .{
            .position = position,
            .label = label,
            .padding = padding,
            .font_size = 50,
            .color = rlc.Color.light_gray,
            .fix_factor = 1.299,
            .shown = true,
        };
    }
    pub fn get_corners(self: Self) [4]Vec(c_int) {
        const dim = rlc.measureTextEx(
            rlc.getFontDefault(),
            self.label,
            @floatFromInt(self.font_size),
            1,
        );
        const shift_x = @as(usize, @intFromFloat(dim.x / 2));
        // FOR SOME REASON, MEASURETEXTEX DOESN'T GIVE THE CORRECT DIMENSIONS,
        // SCALING TOWARDS RIGHT SIDE SEEMS TO MAKE IT LOOK NORMAL
        const shift_scaled_x = @as(usize, @intFromFloat(dim.x / 2 * self.fix_factor));
        const shift_y = @as(usize, @intFromFloat(dim.y / 2));
        return [4]Vec(c_int){
            Vec(c_int).init(
                @intCast(self.position.x - shift_x - self.padding[LEFT]),
                @intCast(self.position.y - shift_y - self.padding[TOP]),
            ),
            Vec(c_int).init(
                @intCast(self.position.x + shift_scaled_x + self.padding[RIGHT]),
                @intCast(self.position.y - shift_y - self.padding[TOP]),
            ),
            Vec(c_int).init(
                @intCast(self.position.x - shift_x - self.padding[LEFT]),
                @intCast(self.position.y + shift_y + self.padding[BOTTOM]),
            ),
            Vec(c_int).init(
                @intCast(self.position.x + shift_scaled_x + self.padding[RIGHT]),
                @intCast(self.position.y + shift_y + self.padding[BOTTOM]),
            ),
        };
    }
    pub fn hover(self: Self) bool {
        const corners = self.get_corners();
        const mouse_pos_f32 = rlc.getMousePosition();
        const mouse_pos = Vec(c_int).init(
            @as(c_int, @intFromFloat(mouse_pos_f32.x)),
            @as(c_int, @intFromFloat(mouse_pos_f32.y)),
        );
        return colliding(
            c_int,
            corners[0],
            Vec(c_int).init(corners[1].x - corners[0].x, corners[2].y - corners[0].y),
            mouse_pos,
            Vec(c_int).init(0, 0),
        );
    }
    pub fn pointer_on_hover(self: Self, make_mouse_pointer: *bool) void {
        if (!self.shown) {
            return;
        }
        if (self.hover()) {
            make_mouse_pointer.* = true;
        }
    }
    pub fn clicked(self: *Self) bool {
        if (!self.shown) {
            return false;
        }
        return rlc.isMouseButtonReleased(rlc.MouseButton.mouse_button_left) and self.hover();
    }
    pub fn draw(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        const corners = self.get_corners();
        const tl = corners[0];
        const tr = corners[1];
        const bl = corners[2];
        const br = corners[3];
        drawText(self.label, self.position.x, self.position.y, self.font_size, self.color);
        rlc.drawLine(tl.x, tl.y, tr.x, tr.y, self.color);
        rlc.drawLine(tr.x, tr.y, br.x, br.y, self.color);
        rlc.drawLine(br.x, br.y, bl.x, bl.y, self.color);
        rlc.drawLine(bl.x, bl.y, tl.x, tl.y, self.color);
    }
    pub fn is_shown(ptr: *anyopaque) *bool {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return &self.shown;
    }
    pub fn drawable(self: *Self) Drawable {
        return .{ .ptr = self, .drawFn = draw, .shownFn = is_shown };
    }
};

pub const Text = struct {
    const Self = @This();
    label: [*c]const u8,
    position: Vec(usize),
    font_size: c_int,
    draw_mode: DrawMode,
    color: rlc.Color,
    shown: bool,

    pub fn init(
        label: [*c]const u8,
        position: Vec(usize),
    ) Self {
        return .{
            .label = label,
            .position = position,
            .font_size = 50,
            .draw_mode = DrawMode.Center,
            .color = rlc.Color.light_gray,
            .shown = true,
        };
    }
    pub fn draw(ptr: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ptr));
        switch (self.draw_mode) {
            .Center => {
                drawText(self.label, self.position.x, self.position.y, self.font_size, self.color);
            },
            .TopLeft => {
                rlc.drawText(
                    self.label,
                    @intCast(self.position.x),
                    @intCast(self.position.y),
                    self.font_size,
                    self.color,
                );
            },
        }
    }
    pub fn is_shown(ptr: *anyopaque) *bool {
        const self: *Self = @ptrCast(@alignCast(ptr));
        return &self.shown;
    }
    pub fn drawable(self: *Self) Drawable {
        return .{ .ptr = self, .drawFn = draw, .shownFn = is_shown };
    }
};

pub const TextureData = struct {
    const Self = @This();
    path: [*:0]const u8,
    sections: c_int,

    pub fn init(path: [*:0]const u8, sections: c_int) Self {
        return .{ .path = path, .sections = sections };
    }
};

const TextureRenderingData = struct {
    const Self = @This();
    texture: rlc.Texture,
    sections: c_int,

    fn init(texture: rlc.Texture, sections: c_int) Self {
        return .{ .texture = texture, .sections = sections };
    }
};

pub const Sprite = struct {
    const Self = @This();
    textures: std.ArrayList(TextureRenderingData),
    frame_rect: rlc.Rectangle,
    position: rlc.Vector2,
    current_texture: usize,
    current_frame: u8,

    pub fn init(
        allocator: std.mem.Allocator,
        sprites_data: []TextureData,
        position: rlc.Vector2,
    ) !Self {
        var textures = try std.ArrayList(TextureRenderingData).initCapacity(
            allocator,
            sprites_data.len,
        );
        for (sprites_data) |sprite_data| {
            textures.appendAssumeCapacity(TextureRenderingData.init(
                rlc.Texture.init(sprite_data.path),
                sprite_data.sections,
            ));
        }
        return .{
            .textures = textures,
            .frame_rect = rlc.Rectangle.init(
                0,
                0,
                @as(f32, @floatFromInt(@divFloor(
                    textures.items[0].texture.width,
                    textures.items[0].sections,
                ))),
                @as(f32, @floatFromInt(textures.items[0].texture.height)),
            ),
            .position = position,
            .current_texture = 0,
            .current_frame = 0,
        };
    }
    pub fn next_frame(self: *Self) void {
        self.set_frame(self.current_frame + 1);
    }
    pub fn set_texture(self: *Self, texture_index: usize) void {
        self.current_texture = texture_index;
        self.frame_rect = rlc.Rectangle.init(
            0,
            0,
            sign(self.frame_rect.width) * @as(f32, @floatFromInt(@divFloor(
                self.textures.items[texture_index].texture.width,
                self.textures.items[texture_index].sections,
            ))),
            @as(f32, @floatFromInt(self.textures.items[texture_index].texture.height)),
        );
        self.set_frame(self.current_frame);
    }
    pub fn set_frame(self: *Self, frame: u8) void {
        self.current_frame = frame % @as(
            u8,
            @intCast(self.textures.items[self.current_texture].sections),
        );
        self.frame_rect.x = @as(f32, @floatFromInt(self.current_frame)) * self.frame_rect.width;
    }
    pub fn deinit(self: Self) void {
        for (self.textures.items) |texture| {
            rlc.unloadTexture(texture.texture);
        }
        self.textures.deinit();
    }
    pub fn draw(self: *Self, scale: usize) void {
        rlc.drawTexturePro(
            self.textures.items[self.current_texture].texture,
            self.frame_rect,
            rlc.Rectangle.init(
                self.position.x,
                self.position.y,
                abs(self.frame_rect.width * @as(f32, @floatFromInt(scale))),
                abs(self.frame_rect.height * @as(f32, @floatFromInt(scale))),
            ),
            rlc.Vector2.init(0.0, 0.0),
            0.0,
            rlc.Color.white,
        );
    }
};
