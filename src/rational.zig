pub const Rational = struct {
    numerator: i32,
    divisor: i32,

    pub fn init(numerator: i32, divisor: i32) Rational {
        return .{ .numerator = numerator, .divisor = divisor };
    }

    pub fn toFloat(self: Rational, comptime T: type) T {
        return @intToFloat(T, self.numerator) / @intToFloat(T, self.divisor);
    }
};
