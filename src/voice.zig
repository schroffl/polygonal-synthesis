const PolyOscillator = @import("./poly_oscillator.zig");
const Rational = @import("./rational.zig").Rational;
const ADSR = @import("./adsr.zig");
const midi = @import("./midi.zig");

const Self = @This();

pub const Mode = union(enum) {
    Mono: PolyOscillator,
    PhaseOffset: PolyOscillator,
};

sample_rate: f32 = 1,
frame_counter: usize = 0,
envelope: ADSR = .{
    .sample_rate = 1,
    .attack = 300.0,
    .decay = 100.0,
    .sustain = 0.7,
    .release = 100,
},

mode: Mode = .{
    .PhaseOffset = .{},
},

volume: f32 = 1,

pub fn sample(self: *Self, left: *f32, right: *f32) void {
    const t = @intToFloat(f32, self.frame_counter) / self.sample_rate;
    const multiplier = self.envelope.sample();

    switch (self.envelope.stage) {
        .idle => {
            left.* = 0;
            right.* = 0;
        },
        else => {
            defer self.frame_counter += 1;

            switch (self.mode) {
                .Mono => |osc| {
                    const v = osc.sample(t).re * multiplier * self.volume;

                    left.* = v;
                    right.* = v;
                },
                .PhaseOffset => |osc| {
                    const complex = osc.sample(t);

                    left.* = complex.re * multiplier * self.volume;
                    right.* = complex.im * multiplier * self.volume;
                },
            }
        },
    }
}

pub fn initFromNoteOn(self: *Self, note_on: midi.NoteOn) void {
    const freq = midi.noteToFrequency(note_on.note);

    self.setOscillatorParam("frequency", @floatCast(f32, freq));
    self.volume = midi.velocityToFloat(f32, note_on.velocity);
    self.frame_counter = 0;
    self.envelope.setGate(true);
}

pub fn setSampleRate(self: *Self, rate: f32) void {
    self.sample_rate = rate;
    self.envelope.sample_rate = rate;
}

pub fn setOscillatorParam(self: *Self, comptime name: []const u8, value: anytype) void {
    switch (self.mode) {
        .Mono, .PhaseOffset => |*osc| {
            @field(osc, name) = value;
        },
    }
}
