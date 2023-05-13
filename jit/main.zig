const std = @import("std");

const gdb = @import("gdb.zig");

const debug = std.debug;
const heap = std.heap;
const log = std.log;
const mem = std.mem;
const os = std.os;

const GeneralPurposeAllocator = heap.GeneralPurposeAllocator;

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    defer debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const source =
        \\jit_get_magic:
        \\        li        a0, 42
        \\        ret
    ;

    const assembly = [_]u8{
        0xB8, 0x2A, 0x00, 0x00, 0x00,
        0xC3,
    };

    var memory = try os.mmap(
        null,
        mem.page_size,
        os.PROT.READ | os.PROT.WRITE,
        os.MAP.PRIVATE | os.MAP.ANONYMOUS,
        -1,
        0,
    );
    defer os.munmap(memory);
    @memcpy(memory[0..assembly.len], &assembly);
    try os.mprotect(memory, os.PROT.EXEC);

    var registry = gdb.DebugRegistry.init(allocator);
    defer registry.deinit();

    try registry.registerCode(.{
        .code = memory.ptr,
        .code_size = assembly.len,
        .source = source,
    });

    const function = @ptrCast(*const fn () callconv(.C) u32, memory);
    const result = function();
    log.info("result: {}", .{result});
}
