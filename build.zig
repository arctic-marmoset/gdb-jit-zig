const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const jit = b.addExecutable(.{
        .name = "jit",
        .root_source_file = .{ .path = "jit/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(jit);

    const reader = b.addSharedLibrary(.{
        .name = "reader",
        .root_source_file = .{ .path = "reader/interface.zig" },
        .target = target,
        .optimize = optimize,
    });
    reader.linkLibC();
    reader.addModule("jit", b.createModule(.{
        .source_file = .{ .path = "jit/jit.zig" },
    }));
    b.installArtifact(reader);

    jit.step.dependOn(&reader.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "jit/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
