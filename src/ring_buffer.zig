const std = @import("std");

pub const RingBuffer = struct {
    allocator: *std.mem.Allocator,
    buffer: []f32,
    head: usize = 0,
    tail: usize = 0,
    count: usize = 0,

    const MultiSpanIterator = struct {
        part1: []const f32,
        part2: []const f32,
        index: usize = 0,

        pub fn read(self: *MultiSpanIterator) ?f32 {
            defer self.index += 1;

            if (self.index < self.part1.len) {
                return self.part1[self.index];
            } else if (self.index < self.part1.len + self.part2.len) {
                return self.part2[self.index - self.part1.len];
            } else {
                return null;
            }
        }
    };

    pub fn init(allocator: *std.mem.Allocator, size: usize) !RingBuffer {
        return RingBuffer{
            .allocator = allocator,
            .buffer = try allocator.alloc(f32, size),
        };
    }

    pub fn write(self: *RingBuffer, value: f32) void {
        self.buffer[self.head] = value;
        self.count = std.math.min(self.count + 1, self.buffer.len);
        self.head = self.wrapIndex(self.head + 1);
    }

    pub fn iterate(self: *RingBuffer) MultiSpanIterator {
        if (self.head > self.tail) {
            const part1 = self.buffer[self.tail..self.head];
            return .{
                .part1 = part1,
                .part2 = &[_]f32{},
            };
        } else {
            const top_len = self.buffer.len - self.tail;
            const top = self.buffer[top_len..];
            const bottom = self.buffer[0..self.head];

            return .{
                .part1 = top,
                .part2 = bottom,
            };
        }
    }

    pub fn read(self: *RingBuffer) ?f32 {
        if (self.count > 0) {
            defer {
                self.count -= 1;
                self.tail = self.wrapIndex(self.tail + 1);
            }

            return self.buffer[self.tail];
        }

        return null;
    }

    pub fn peekAt(self: *RingBuffer, index: usize) ?f32 {
        if (self.count >= index) {
            const read_index = self.wrapIndex(self.tail + index);
            return self.buffer[read_index];
        }

        return null;
    }

    fn wrapIndex(self: RingBuffer, idx: usize) usize {
        if (idx >= self.buffer.len) {
            return idx - self.buffer.len;
        }

        return idx;
    }
};
