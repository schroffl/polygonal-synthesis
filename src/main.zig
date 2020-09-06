const vst = @import("zig-vst");
const PolySynth = @import("./poly_synth.zig").PolySynth;

pub usingnamespace @import("./complex.zig");
pub usingnamespace @import("./rational.zig");

const Plugin = vst.VstPlugin(.{
    .id = 0x8a9f89e,
    .version = [_]u8{ 0, 0, 1, 0 },
    .flags = &[_]vst.api.Plugin.Flag{ .IsSynth, .CanReplacing },
    .input = &[_]vst.audio_io.Channel{},
    .output = &[_]vst.audio_io.Channel{
        .{
            .name = "Left",
            .arrangement = .{ .Stereo = {} },
        },
        .{
            .name = "Right",
            .arrangement = .{ .Stereo = {} },
        },
    },
}, PolySynth);

pub usingnamespace Plugin.generateTopLevelHandlers();

comptime {
    Plugin.generateExports({});
}
