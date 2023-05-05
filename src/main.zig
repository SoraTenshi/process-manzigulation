// STD calls
const std = @import("std");
const windows = std.os.windows;

// Win Lib
const win = @import("win");
const zwin = win.everything;

// Imports
const hook = @import("zig_bait");

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
    _ = zwin.MessageBoxA(null, "Test", "Successfully injected.", zwin.MB_OK);
    const vmt_hook = hook.vmt.init(&hooked_print, hook.vmt.addressToVtable(0x00000000004E3EA0), 1) catch return 0;
    std.debug.print("[*] past init\n", .{});
    hook.global_hooks.?.append(vmt_hook) catch @panic("OOM");

    var option = hook.global_hooks.?.getLast().hook_option;
    option.vmt_option.enableDebug();
    return 0;
}

fn unload() callconv(.C) void {
    hook.restoreAll();
    hook.global_hooks.?.deinit();
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
