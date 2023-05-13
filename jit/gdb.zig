const std = @import("std");

const jit = @import("jit.zig");

const debug = std.debug;
const heap = std.heap;
const mem = std.mem;
const meta = std.meta;

const Allocator = mem.Allocator;
const MemoryPool = heap.MemoryPool;

pub const DebugRegistry = struct {
    allocator: Allocator,
    head: ?*JitCodeEntry = null,
    tail: ?*JitCodeEntry = null,

    pub fn init(allocator: Allocator) DebugRegistry {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: DebugRegistry) void {
        self.clearAllEntries();
    }

    fn clearAllEntries(self: DebugRegistry) void {
        var walker = self.head;
        while (walker) |entry| : (walker = entry.next) {
            self.allocator.destroy(entry);
        }
    }

    pub const RegisterCodeInfo = struct {
        code: *align(16) const anyopaque,
        code_size: usize,
        source: []const u8,
    };

    pub fn registerCode(self: *DebugRegistry, info: RegisterCodeInfo) !void {
        _ = info;

        const entry = try self.createEntry();
        __jit_debug_descriptor.action = .register;
        __jit_debug_descriptor.first_entry = entry;
        __jit_debug_descriptor.relevant_entry = entry;
        __jit_debug_register_code();
    }

    const test_symbol: jit.Symbol = .{};

    fn createEntry(self: *DebugRegistry) !*JitCodeEntry {
        const entry = try self.allocator.create(JitCodeEntry);
        errdefer self.allocator.destroy(entry);
        entry.* = .{
            .symfile_address = &test_symbol,
            .symfile_size = @sizeOf(@TypeOf(test_symbol)),
        };

        if (self.head == null) {
            self.head = entry;
            self.tail = entry;
        } else {
            const prev = self.tail.?;
            prev.next = entry;
            entry.prev = prev;
            self.tail = entry;
        }

        return entry;
    }
};

const JitAction = enum(u32) {
    none,
    register,
    unregister,
};

const JitCodeEntry = extern struct {
    next: ?*JitCodeEntry = null,
    prev: ?*JitCodeEntry = null,
    symfile_address: *const jit.Symbol,
    symfile_size: u64,
};

const JitDescriptor = extern struct {
    version: u32,
    action: JitAction = .none,
    relevant_entry: ?*const JitCodeEntry = null,
    first_entry: ?*const JitCodeEntry = null,
};

export fn __jit_debug_register_code() callconv(.C) void {
    asm volatile ("");
}

export var __jit_debug_descriptor: JitDescriptor = .{
    .version = 1,
};
