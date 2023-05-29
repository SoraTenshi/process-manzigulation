const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const win = b.dependency("zigwin32", .{});
    const zig_bait = b.dependency("zig_bait", .{});
    const zigwin_console = b.dependency("zigwin_console", .{});

    const vmt_hook_test = b.addSharedLibrary(.{
        .name = "vmt_hook_test",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{ .os_tag = .windows },
        .optimize = optimize,
    });

    vmt_hook_test.addModule("win", win.module("zigwin32"));
    vmt_hook_test.addModule("zig_bait", zig_bait.module("zig-bait"));
    vmt_hook_test.addModule("zigwin_console", zigwin_console.module("zigwin-console"));
    b.installArtifact(vmt_hook_test);
}
