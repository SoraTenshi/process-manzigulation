const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const win = b.dependency("zigwin32", .{});
    const zig_bait = b.dependency("zig_bait", .{});

    const vmt_hook_test = b.addSharedLibrary(.{
        .name = "vmt_hook_test",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{ .os_tag = .windows },
        .optimize = optimize,
    });

    vmt_hook_test.addModule("win", win.module("zigwin32"));
    vmt_hook_test.addModule("zig_bait", zig_bait.module("zig-bait"));
    b.installArtifact(vmt_hook_test);
}
