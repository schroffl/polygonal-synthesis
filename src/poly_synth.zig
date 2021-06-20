const std = @import("std");
const Rational = @import("./rational.zig").Rational;

pub const PolyOscillator = struct {
    frequency: f32 = 440,
    detune: f32 = 0,
    order: Rational = Rational.init(54, 10),
    teeth: f32 = 0.1,
    phase: f32 = 0,

    const two_pi = @as(f32, std.math.pi) * 2;

    pub fn sample(self: PolyOscillator, t: f32) f32 {
        const fundamental = two_pi * (self.frequency + self.detune);
        const angle = fundamental * t * cycles(self.order);

        // TODO Find out why the phasor seems to be rotating in the wrong direction
        //      (which is why it says -angle below).
        return project(-angle, self.order, self.teeth, self.phase);
    }

    pub fn samplePhaseOffset(self: PolyOscillator, t: f32) f32 {
        const fundamental = two_pi * (self.frequency + self.detune);
        const angle = fundamental * t * cycles(self.order);
        const a = amplitude(angle, self.order, self.teeth);

        return a * std.math.sin(-angle + self.phase);
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
        const magnitude = amplitude(phi, order, teeth);

        // Polar coordinates to cartesian:
        return magnitude * std.math.cos(phi + phase);
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
