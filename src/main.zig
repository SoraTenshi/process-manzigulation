// STD calls
const std = @import("std");
const windows = std.os.windows;

// Win Lib
const win = @import("win");
const zwin = win.everything;

// Imports
const hook = @import("zig_bait");
const Console = @import("zigwin_console").Console;

var console: ?Console = null;
var hooks: ?hook.HookManager = null;

export fn hooked_print(base: *anyopaque) callconv(.C) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("Successfully hooked to address: 0x{x:0>16}, coming from base class: 0x{x:0>16}\n", .{ @intFromPtr(&hooked_print), @intFromPtr(base) }) catch {
        _ = zwin.MessageBoxA(null, "This should not have happened", "aaaaa", zwin.MB_OK);
        return;
    };
    if (hooks.?.getOriginalFunction(&hooked_print)) |original| {
        std.debug.print("Calling original @0x{x:0>16} with type: {*}\n", .{ @intFromPtr(original), original });
        original(base);
    } else {
        stdout.print("calling orig fn failed.\n", .{}) catch return;
    }
    hooks.?.deinit();
}

export fn initiate(_: ?*anyopaque) callconv(.C) u32 {
    console = Console.init("This is my testing console", true) catch null;
    hooks = hook.HookManager.init(std.heap.page_allocator);
    if (console) |*c| {
        c.print(.good, "This is a {s}\n", .{"test"}) catch {};
        c.print(.info, "This is a {s}\n", .{"test"}) catch {};
        c.print(.bad, "This is a {s}\n", .{"test"}) catch {};
    }

    hooks.?.append_vmt(
        std.heap.page_allocator,
        .safe_vmt,
        0x00000000005344A0,
        &.{1},
        &.{@intFromPtr(&hooked_print)},
    ) catch {};
    return 0;
}

fn unload() callconv(.C) void {
    hooks.?.deinit();
    console.?.deinit();
}

pub export fn DllMain(_: windows.HINSTANCE, reason: windows.DWORD, reserved: ?windows.LPVOID) windows.BOOL {
    switch (reason) {
        zwin.DLL_PROCESS_ATTACH => {
            const thread = zwin.CreateThread(null, 0, &initiate, null, .THREAD_CREATE_RUN_IMMEDIATELY, null);
            if (thread != null) {
                windows.CloseHandle(thread orelse return windows.FALSE);
            }
        },
        zwin.DLL_PROCESS_DETACH => {
            if (reserved == null) {
                unload();
            }
        },
        else => return windows.FALSE,
    }

    return windows.TRUE;
}
