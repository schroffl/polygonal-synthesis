const std = @import("std");

pub const Complex = struct {
    pub const T = f32;

    re: T,
    im: T,

    pub fn init(re: T, im: T) Complex {
        return .{ .re = re, .im = im };
    }

    pub fn fromReal(re: T) Complex {
        return .{ .re = re, .im = 0 };
    }

    pub fn fromImaginary(im: T) Complex {
        return .{ .re = 0, .im = im };
    }

    pub fn add(a: Complex, b: Complex) Complex {
        return .{
            .re = a.re + b.re,
            .im = a.im + b.im,
        };
    }

    /// Subtract the second argument from the first argument!
    /// This operation is not commutative, so the order of arguments matters.
    pub fn subtract(a: Complex, b: Complex) Complex {
        return .{
            .re = a.re - b.re,
            .im = a.im - b.im,
        };
    }

    pub fn multiply(a: Complex, b: Complex) Complex {
        return .{
            .re = a.re * b.re - a.im * b.im,
            .im = a.re * b.im + b.re * a.im,
        };
    }

    /// Useful for the special case of raising e to the power of an imaginary number.
    ///
    /// e^(0 + exp * i) = cos(exp) + i * sin(exp)
    /// where i^2 = -1
    ///
    /// Sidenote: Now I get why e^πi = -1
    ///
    /// See https://www.math.toronto.edu/mathnet/questionCorner/complexexp.html
    pub fn moivre(exp: f32) Complex {
        return .{
            .re = std.math.cos(exp),
            .im = std.math.sin(exp),
        };
    }
};

test "add" {
    // This is here to catch errors in functions that don't have a test
    // and aren't use anywhere in code.
    std.meta.refAllDecls(Complex);

    const a = Complex.init(1, 3);
    const b = Complex.init(3, -2);
    const result = Complex.add(a, b);

    std.testing.expectEqual(@as(Complex.T, 4), result.re);
    std.testing.expectEqual(@as(Complex.T, 1), result.im);
}

test "subtract" {
    const a = Complex.init(7, -5);
    const b = Complex.init(-3, 3);
    const result = Complex.subtract(a, b);

    std.testing.expectEqual(@as(Complex.T, 10), result.re);
    std.testing.expectEqual(@as(Complex.T, -8), result.im);
}

test "multiply" {
    const a = Complex.init(3, 4);
    const b = Complex.init(5, 2);
    const result = Complex.multiply(a, b);

    std.testing.expectEqual(@as(Complex.T, 7), result.re);
    std.testing.expectEqual(@as(Complex.T, 26), result.im);
}

test "moivre" {
    // TODO
}
