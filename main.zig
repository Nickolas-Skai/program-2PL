const std = @import("std");

pub fn main() void {
    display_bnf();

    const stdin = std.io.getStdIn().reader(); // Changed var to const
    var input: [256]u8 = undefined;

    while (true) {
        std.debug.print("Enter an input string (or type 'END' to quit): ", .{});

        const result = stdin.readUntilDelimiterOrEof(&input, '\n') catch { // Changed var to const
            std.debug.print("Failed to read input\n", .{});
            return;
        };

        const input_slice = result orelse { // Changed var to const
            std.debug.print("No input read\n", .{});
            return;
        };

        const trimmed_input = std.mem.trimRight(u8, input_slice, "\n"); // Changed var to const

        if (std.mem.eql(u8, trimmed_input, "END")) {
            break;
        }

        const validation = validate_input(trimmed_input); // Changed var to const
        if (validation == null) {
            draw_parse_tree(trimmed_input);
            generate_pbasic_program(trimmed_input);
        } else {
            std.debug.print("Error: {}\n", .{validation});
        }

        std.debug.print("Press any key to continue...", .{});
        _ = stdin.readByte() catch {};
    }
}

fn validate_input(input: []const u8) ?[]const u8 {
    if (input.len == 0) {
        return "Expected Instructions; Received null";
    }

    if (std.mem.eql(u8, input, "ABORT")) {
        std.debug.print("Aborting program...\n", .{});
        std.os.exit(0);
    }

    if (std.mem.indexOf(u8, input, "wake") == null) {
        return "'wake' must be included";
    }

    if (std.mem.indexOf(u8, input, "sleep") == null) {
        return "'sleep' must be included";
    }

    const wake_count = count_occurrences(input, "wake"); // Changed var to const
    const sleep_count = count_occurrences(input, "sleep"); // Changed var to const

    if (wake_count != 1 or sleep_count != 1) {
        return "The input should have exactly one 'wake' and one 'sleep'";
    }

    if (!std.mem.startsWith(u8, input, "wake")) {
        return "The input string should start with 'wake'";
    }

    if (!std.mem.endsWith(u8, input, "sleep")) {
        return "The input string should end with 'sleep'";
    }

    // Attempt leftmost derivation based on BNF grammar
    if (!check_input(input)) {
        return "Input does not match the BNF grammar.";
    }

    return null;
}

fn count_occurrences(input: []const u8, sequence: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i <= input.len - sequence.len) {
        if (std.mem.eql(u8, input[i..i + sequence.len], sequence)) {
            count += 1;
            i += sequence.len;
        } else {
            i += 1;
        }
    }
    return count;
}

fn check_input(input: []const u8) bool {
    // Existing check_input logic
}

fn draw_parse_tree(input: []const u8) void {
    var tokens = input.split(" ");
    var tree = std.ArrayList([]const u8).init(std.heap.page_allocator);

    for (tokens) |token| {
        tree.append(token) catch {
            std.debug.print("Failed to append token to tree\n", .{});
            return;
        };
    }

    std.debug.print("Parse Tree:\n", .{});
    for (tree.items) |node| {
        std.debug.print("{}\n", .{node});
    }
}

fn generate_pbasic_program(input: []const u8) void {
    var pbasic_program = std.ArrayList([]const u8).init(std.heap.page_allocator);

    const header = "HEADER\n";
    const footer1 = "FOOTER1\n";
    const subroutine = "SUBROUTINE\n";
    const footer2 = "FOOTER2\n";

    pbasic_program.append(header) catch {};
    pbasic_program.append(footer1) catch {};
    pbasic_program.append(subroutine) catch {};
    pbasic_program.append(footer2) catch {};

    var tokens = input.split(" ");
    for (tokens) |token| {
        if (std.mem.indexOf(u8, token, "=") != null) {
            const body = "BODY " ++ token ++ "\n";
            pbasic_program.append(body) catch {};
        }
    }

    std.debug.print("Generated PBASIC Program:\n", .{});
    for (pbasic_program.items) |line| {
        std.debug.print("{}\n", .{line});
    }

    const file = try std.fs.cwd().createFile("IZEBOT.BSP", .{});
    defer file.close();

    file.writeAll(pbasic_program.toSliceConst()) catch {
        std.debug.print("Failed to write PBASIC program to file\n", .{});
        return;
    };

    std.debug.print("PBASIC program saved to IZEBOT.BSP\n", .{});
}

pub fn display_bnf() void {
    std.debug.print("<program>      →     wake <controls> sleep\n", .{});
    std.debug.print("<controls>     →     <control>\n", .{});
    std.debug.print("               |     <control> <controls>\n", .{});
    std.debug.print("<control>      →     <letter> = <movement>\n", .{});
    std.debug.print("<letter>       →     a | b | c | d\n", .{});
    std.debug.print("<movement>     →     DRIVE | BACK | LEFT | RIGHT | SPINL | SPINR\n", .{});
}