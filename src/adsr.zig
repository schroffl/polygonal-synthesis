const Self = @This();

const Stage = enum {
    idle,
    attack,
    decay,
    sustain,
    release,
};

/// Sample rate in samples per second
sample_rate: f32,

/// Attack time in milliseconds
attack: f32,
/// Decay time in milliseconds
decay: f32,
/// Sustain volume in the range [0, 1]
sustain: f32,
/// Release time in milliseconds
release: f32,

stage: Stage = .idle,
frame_counter: f32 = 0,
prev_gate: bool = false,
release_from: f32 = 0,

last_value: f32 = 0,

pub fn setGate(self: *Self, gate: bool) void {
    if (gate) {
        switch (self.stage) {
            .attack, .decay, .sustain => {},
            .idle => {
                self.stage = .attack;
                self.frame_counter = 0;
            },
            .release => {
                const samples_attack = self.millisToSamples(self.attack);
                self.frame_counter = self.last_value * samples_attack;
                self.stage = .attack;
            },
        }
    } else if (self.stage != .idle and self.stage != .release) {
        self.stage = .release;
        self.frame_counter = 0;
    }
}

fn millisToSamples(self: Self, millis: f32) f32 {
    return millis * self.sample_rate / 1000;
}

pub fn sample(self: *Self) f32 {
    self.last_value = self.sampleInternal();
    return self.last_value;
}

fn sampleInternal(self: *Self) f32 {
    return switch (self.stage) {
        .attack => {
            const samples_attack = self.millisToSamples(self.attack);

            if (self.frame_counter >= samples_attack) {
                self.frame_counter = 0;
                self.release_from = 1;
                self.stage = .decay;

                return 1;
            } else {
                const value = self.frame_counter / samples_attack;
                self.release_from = value;
                self.frame_counter += 1;
                return value;
            }
        },
        .decay => {
            const samples_decay = self.millisToSamples(self.decay);

            if (self.frame_counter >= samples_decay) {
                self.frame_counter = 0;
                self.release_from = self.sustain;
                self.stage = .sustain;
                return self.sustain;
            } else {
                const progress = self.frame_counter / samples_decay;
                const value_range = 1 - self.sustain;
                const value = 1 - value_range * progress;

                self.frame_counter += 1;
                self.release_from = value;
                return value;
            }
        },
        .sustain => {
            return self.sustain;
        },
        .release => {
            const samples_release = self.millisToSamples(self.release);

            if (self.frame_counter >= samples_release) {
                self.frame_counter = 0;
                self.release_from = 0;
                self.stage = .idle;
                return 0;
            } else {
                const progress = self.frame_counter / samples_release;
                self.frame_counter += 1;
                return self.release_from - (self.release_from * progress);
            }
        },
        .idle => return 0,
    };
}
