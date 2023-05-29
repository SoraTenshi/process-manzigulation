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

export fn hooked_print(base: *anyopaque) callconv(.C) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("Successfully hooked to address: 0x{x:0>16}, coming from base class: 0x{x:0>16}\n", .{ @ptrToInt(&hooked_print), @ptrToInt(base) }) catch {
        _ = zwin.MessageBoxA(null, "This should not have happened", "aaaaa", zwin.MB_OK);
        return;
    };
    const entry = hook.global_hooks.?.getLast().hook_option.vmt_option;
    if (entry.getOriginalFunction(&hooked_print)) |original| {
        std.debug.print("Calling original @0x{x:0>16} with type: {*}\n", .{ @ptrToInt(original), original });
        original(base);
    } else |err| {
        stdout.print("calling orig fn failed. err: {any}\n", .{err}) catch return;
    }
}

export fn initiate(_: ?*anyopaque) callconv(.C) u32 {
    console = Console.init("This is my testing console", false) catch null;
    const vmt_hook = hook.safe_vmt.init(&hooked_print, hook.vmt.addressToVtable(0x00000000004F5070), 1, std.heap.page_allocator) catch return 0;
    if (console) |*c| {
        c.print(.good, "This is a {s}\n", .{"test"}) catch {};
        c.print(.info, "This is a {s}\n", .{"test"}) catch {};
        c.print(.bad, "This is a {s}\n", .{"test"}) catch {};
    }

    std.debug.print("[*] past init\n", .{});
    hook.global_hooks.?.append(vmt_hook) catch @panic("OOM");

    var option = hook.global_hooks.?.getLast().hook_option;
    option.vmt_option.enableDebug();
    return 0;
}

fn unload() callconv(.C) void {
    hook.restoreAll();
    hook.global_hooks.?.deinit();
    console.?.deinit();
}

pub export fn DllMain(_: windows.HINSTANCE, reason: windows.DWORD, reserved: ?windows.LPVOID) windows.BOOL {
    switch (reason) {
        zwin.DLL_PROCESS_ATTACH => {
            hook.global_hooks = hook.HookArrayList.init(std.heap.page_allocator);
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
