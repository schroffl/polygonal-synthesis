const std = @import("std");
const vst_build = @import("./lib/zig-vst/src/build_step.zig");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const version = std.builtin.Version{
        .major = 0,
        .minor = 1,
        .patch = 0,
    };

    // For some reason a versioned shared library causes zig build to crash
    // on windows.
    const target_tag = target.os_tag orelse std.Target.current.os.tag;

    var bundle_step = vst_build.create(b, "src/main.zig", .{
        .name = "zig-poly-synth",
        .identifier = "org.zig-poly-synth",
        .version = if (target_tag == .windows) null else version,
        .target = target,
        .mode = mode,
    });

    var reload_step = bundle_step.autoReload();

    b.default_step.dependOn(&reload_step.step);
}
