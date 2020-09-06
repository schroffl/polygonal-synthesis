const std = @import("std");
const RingBuffer = @import("./ring_buffer.zig").RingBuffer;

pub const Filter = struct {
    history: RingBuffer,
    coefficients: []const f32,

    pub fn init(allocator: *std.mem.Allocator, coefficients: []const f32) !Filter {
        return Filter{
            .history = try RingBuffer.init(allocator, coefficients.len),
            .coefficients = coefficients,
        };
    }

    pub fn process(self: *Filter, sample: f32) f32 {
        var iterator = self.history.iterate();
        var i: usize = 1;
        var result = sample * self.coefficients[0];

        while (iterator.read()) |prev| {
            const coeff = self.coefficients[i];
            i += 1;

            result += coeff * prev;
        }

        self.history.write(result);

        return result;
    }
};
