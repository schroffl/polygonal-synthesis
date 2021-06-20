const std = @import("std");
const zig_vst = @import("zig-vst");
const api = zig_vst.api;

const midi = @import("./midi.zig");
const Voice = @import("./voice.zig");

var log_writer: ?std.fs.File.Writer = null;
var log_file: ?std.fs.File = null;

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .emerg => "emergency",
        .alert => "alert",
        .crit => "critical",
        .err => "error",
        .warn => "warning",
        .notice => "notice",
        .info => "info",
        .debug => "debug",
    };
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    if (log_writer) |writer| {
        writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
    }
}

pub fn panic(err: []const u8, maybe_trace: ?*std.builtin.StackTrace) noreturn {
    if (log_file) |file| {
        var writer = file.writer();
        writer.writeAll("\nPanic: ") catch unreachable;
        writer.writeAll(err) catch unreachable;

        if (maybe_trace) |trace| writer.print("{}\n", .{trace}) catch unreachable;
    }

    while (true) {
        @breakpoint();
    }
}

var voice: Voice = undefined;

export fn VSTPluginMain(callback: api.HostCallback) ?*api.AEffect {
    var allocator = std.heap.page_allocator;
    var effect = allocator.create(api.AEffect) catch unreachable;

    voice = .{
        .sample_rate = undefined,
    };

    effect.* = .{
        .dispatcher = onDispatch,
        .setParameter = setParameter,
        .getParameter = getParameter,
        .processReplacing = processReplacing,
        .processReplacingF64 = processReplacingF64,

        .unique_id = 0x8a9f89e,
        .initial_delay = 0,
        .version = 0,

        .num_programs = 0,
        .num_params = 0,
        .num_inputs = 2,
        .num_outputs = 2,
        .flags = api.Plugin.Flag.toBitmask(&[_]api.Plugin.Flag{
            .CanReplacing, .IsSynth,
        }),
    };

    const cwd = std.fs.cwd();
    const log_path = std.fs.path.resolve(allocator, &[_][]const u8{
        @src().file,
        "../../zig-poly-synth.log",
    }) catch unreachable;

    log_file = cwd.createFile(log_path, .{}) catch unreachable;
    log_writer = log_file.?.writer();

    return effect;
}

fn onDispatch(
    effect: *api.AEffect,
    opcode: i32,
    index: i32,
    value: isize,
    ptr: ?*c_void,
    opt: f32,
) callconv(.C) isize {
    const hl = api.HighLevelCode.parse(opcode, index, value, ptr, opt);

    if (hl) |high_level_code| {
        switch (high_level_code) {
            .GetTailSize => return 1,
            .SetSampleRate => |rate| {
                voice.setSampleRate(rate);
            },
            .SetBufferSize => |buffer_size| {},
            .ProcessEvents => |events| {
                var it = events.iterate();

                while (it.next()) |raw| {
                    const event = api.Event.parse(raw);

                    switch (event) {
                        .Midi => |payload| {
                            const msg = midi.Message.parse(&payload.data);

                            switch (msg) {
                                .NoteOn => |note_on| {
                                    voice.initFromNoteOn(note_on);
                                },
                                .NoteOff => |note_off| {
                                    voice.envelope.setGate(false);
                                },
                                .ControlChange => |cc| {
                                    const cc_value = @intToFloat(f32, cc.value) / 127;

                                    voice.setOscillatorParam("teeth", cc_value * 3);
                                },
                                .PitchBend => |bend| {
                                    const v = @intToFloat(f32, bend.value);
                                    const max = std.math.maxInt(@TypeOf(bend.value));
                                    const normalized = v / @intToFloat(f32, max);

                                    const R = @import("./rational.zig").Rational;
                                    const t = std.math.floor(normalized * 20 + 30);
                                    const r = R.init(@floatToInt(i32, t), 10);

                                    voice.setOscillatorParam("order", r);
                                },
                                else => {},
                            }
                        },
                    }
                }
            },
            .GetProductName => |buf| {
                _ = zig_vst.helper.setBuffer(u8, buf, "zig-poly-synth", api.ProductNameMaxLength);
            },
            .GetVendorName => |buf| {
                _ = zig_vst.helper.setBuffer(u8, buf, "schroffl", api.VendorNameMaxLength);
            },
            .GetApiVersion => return 2400,
            else => {},
        }
    } else {
        std.log.warn("Unknown opcode: {}", .{opcode});
    }

    return 0;
}

fn setParameter(effect: *api.AEffect, index: i32, parameter: f32) callconv(.C) void {}

fn getParameter(effect: *api.AEffect, index: i32) callconv(.C) f32 {
    return 0;
}

const BufferLayout = &[_]zig_vst.audio_io.Channel{
    .{
        .name = "Left",
        .short = "L",
        .arrangement = .Stereo,
    },
    .{
        .name = "Right",
        .short = "R",
        .arrangement = .Stereo,
    },
};

const Buffer = zig_vst.audio_io.AudioBuffer(BufferLayout, f32);
var frames_total: usize = 0;

fn processReplacing(
    effect: *api.AEffect,
    inputs: [*][*]f32,
    outputs: [*][*]f32,
    num_frames: i32,
) callconv(.C) void {
    const frame_count = @intCast(usize, num_frames);
    const in = Buffer.fromRaw(inputs, frame_count);
    var out = Buffer.fromRaw(outputs, frame_count);

    var i: usize = 0;

    var left_buf = out.getBuffer("Left");
    var right_buf = out.getBuffer("Right");

    while (i < frame_count) : (i += 1) {
        const t = @intToFloat(f32, frames_total) / voice.sample_rate;
        frames_total += 1;
        voice.sample(&left_buf[i], &right_buf[i]);
    }
}

fn processReplacingF64(effect: *api.AEffect, inputs: [*][*]f64, outputs: [*][*]f64, frames: i32) callconv(.C) void {
    std.log.warn("processReplacingF64 called", .{});
}
