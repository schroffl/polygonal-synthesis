const std = @import("std");
const vst_build = @import("./zig-vst/src/main.zig").build_util;

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const vst = vst_build.BuildStep.create(b, "src/main.zig", .{
        .name = "Polygonal Synthesis",
        .version = .{
            .major = 0,
            .minor = 0,
            .patch = 0,
        },
        .macos_bundle = .{
            .bundle_identifier = "org.zig-vst.poly-synth",
            .bundle_signature = "poly".*,
        },
        .self_path = "./zig-vst",
        .mode = mode,
    });

    addPackage(vst.getLibStep());

    const normal_build = b.step("normal-build", "Build the VST without hot reloading");
    normal_build.dependOn(vst.step);

    const hot_reload = vst.hotReload();
    b.default_step.dependOn(&hot_reload.step);

    const hot_reload_logs = b.step("hr-logs", "Display the logs of the hot reload wrapper in real-time");
    hot_reload_logs.dependOn(hot_reload.trackLogs());

    var test_step = b.addTest("src/main.zig");
    addPackage(test_step);
    const run_tests = b.step("test", "Run library tests");
    run_tests.dependOn(&test_step.step);
}

fn addPackage(step: *std.build.LibExeObjStep) void {
    step.addPackagePath("zig-vst", "zig-vst/src/main.zig");
}
