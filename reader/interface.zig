const std = @import("std");

const jit = @import("jit");

const c = @import("c.zig");

const heap = std.heap;
const log = std.log;
const math = std.math;

const Reader = @import("Reader.zig");

const Self = @This();

var reader: Reader = undefined;

export fn gdb_init_reader() callconv(.C) ?*const c.gdb_reader_funcs {
    log.info("initialising reader", .{});

    reader.init() catch |e| {
        log.err("failed to initialise reader: {}", .{e});
        return null;
    };

    return &.{
        .reader_version = c.GDB_READER_INTERFACE_VERSION,
        .priv_data = null,
        .read = read,
        .unwind = unwind,
        .get_frame_id = getFrameId,
        .destroy = destroy,
    };
}

fn destroy(context: ?*c.gdb_reader_funcs) callconv(.C) void {
    _ = context;

    log.info("destroying reader", .{});
    reader.deinit();
}

fn read(
    context: ?*c.gdb_reader_funcs,
    cb: ?*c.gdb_symbol_callbacks,
    memory: ?*anyopaque,
    memory_size: c_long,
) callconv(.C) c.gdb_status {
    _ = cb;
    _ = context;

    log.info("READ address: 0x{X} ({} Bytes)", .{ @ptrToInt(memory), memory_size });

    const symbol = @ptrCast(*const jit.Symbol, @alignCast(@alignOf(jit.Symbol), memory));
    log.info("symbol: {{ magic: {X} }}", .{symbol.magic});

    return c.GDB_SUCCESS;
}

fn unwind(
    context: ?*c.gdb_reader_funcs,
    cb: ?*c.gdb_unwind_callbacks,
) callconv(.C) c.gdb_status {
    _ = cb;
    _ = context;

    log.info("UNWIND", .{});

    return c.GDB_SUCCESS;
}

fn getFrameId(
    context: ?*c.gdb_reader_funcs,
    cb: ?*c.gdb_unwind_callbacks,
) callconv(.C) c.gdb_frame_id {
    _ = cb;
    _ = context;

    log.info("GET FRAME ID", .{});

    return .{
        .code_address = math.maxInt(c.GDB_CORE_ADDR),
        .stack_address = math.maxInt(c.GDB_CORE_ADDR),
    };
}

export fn plugin_is_GPL_compatible() callconv(.C) c_int {
    return 0;
}
