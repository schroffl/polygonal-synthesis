const std = @import("std");
const Complex = @import("./complex.zig").Complex;
const Rational = @import("./rational.zig").Rational;
const Filter = @import("./filter.zig").Filter;

//! TODO Once these points are done, we should have a usable sound at last.
//!
//!  [ ] - Have a sin(x) function that doesn't deviate for a growing x.
//!        At least this seems to be the case with std.math.sin, but I'm not sure.
//!
//!  [ ] - Anti-alias the signal. Oversample by a factor of 4, apply a
//!        high-order low-pass filter with the cutoff at the nyquist limit.
//!
//!  [ ] - Implement amplitude limiting
//!
//!  [ ] - Implement DC blocker
//!
//!

pub const PolySynth = struct {
    rand: *std.rand.Random,
    frame_counter: usize,
    osc: PolyOscillator,

    pub fn create(self: *PolySynth, allocator: *std.mem.Allocator) !void {
        const t = std.time.milliTimestamp();

        const RngT = std.rand.Isaac64;
        var rng = try allocator.create(RngT);
        rng.* = RngT.init(@intCast(u64, t));

        self.rand = &rng.random;
        self.frame_counter = 0;
        self.osc = .{};
    }

    pub fn process(self: *PolySynth, input: anytype, output: anytype) void {
        var i: usize = 0;

        while (i < output.frames) : (i += 1) {
            self.frame_counter += 1;

            const t: f32 = @intToFloat(f32, self.frame_counter) / 44100.0;
            const sample = self.osc.sample(t);

            output.setFrame("Left", i, sample);
            output.setFrame("Right", i, sample);
        }
    }
};

pub const PolyOscillator = struct {
    frequency: f32 = 200,
    order: Rational = Rational.init(500, 100),
    teeth: f32 = 0,

    const two_pi = @as(f32, std.math.pi) * 2;

    pub fn sample(self: PolyOscillator, t: f32) f32 {
        const fundamental = two_pi * self.frequency;
        const angle = fundamental * t * cycles(self.order);

        // TODO Find out why the phasor seems to be rotating in the wrong direction
        //      (which is why it says -angle below).
        return project(-angle, self.order, self.teeth, 0) * 0.3;
    }

    fn cycles(order: Rational) f32 {
        const frac = std.math.mod(i32, order.numerator, order.divisor) catch unreachable;
        const div = gcd(i32, frac, order.divisor) catch unreachable;

        return @intToFloat(f32, order.divisor) / @intToFloat(f32, div);
    }

    test "cycles" {
        std.testing.expectEqual(@as(f32, 5), cycles(Rational.init(36, 10)));
        std.testing.expectEqual(@as(f32, 5), cycles(Rational.init(54, 10)));
        std.testing.expectEqual(@as(f32, 5), cycles(Rational.init(27, 5)));
        std.testing.expectEqual(@as(f32, 100), cycles(Rational.init(333, 100)));
    }

    /// Calculate the amplitude of a polygon.
    ///
    /// phi represents the angle for which we want to calculate the amplitude.
    fn amplitude(phi: f32, order: Rational, teeth: f32) f32 {
        const n = order.toFloat(f32);
        const two_pi_over_order = two_pi / n;
        const mod_result = std.math.mod(f32, phi * n / two_pi, 1) catch unreachable;
        const offset = std.math.pi / n + teeth;

        const result = two_pi_over_order * mod_result - offset;

        return std.math.cos(std.math.pi / n) / std.math.cos(result);
    }

    fn project(phi: f32, order: Rational, teeth: f32, phase: f32) f32 {
        const base = Complex.init(std.math.e, 0);
        const exp = Complex.init(0, phi + phase);
        const e_pow_phi_times_phase = Complex.moivre(phi + phase);

        const poly = amplitude(phi, order, teeth);
        const poly_complex = Complex.fromReal(poly);

        const result = Complex.multiply(poly_complex, e_pow_phi_times_phase);

        return result.re;
    }
};

fn gcd(comptime T: type, a: T, b: T) !T {
    var temp_a = a;
    var temp_b = b;

    while (temp_b != 0) {
        var old_b = temp_b;
        temp_b = try std.math.mod(T, temp_a, temp_b);
        temp_a = old_b;
    }

    return temp_a;
}

test "gcd" {
    std.testing.expectEqual(@as(f32, 20), try gcd(f32, 60, 100));
    std.testing.expectEqual(@as(u8, 20), try gcd(u8, 60, 100));
    std.testing.expectEqual(@as(f64, 2), try gcd(f64, 2938, 342));
}
