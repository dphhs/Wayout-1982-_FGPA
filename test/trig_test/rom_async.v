`timescale 1ns / 1ps
`default_nettype none

// Asynchronous read ROM
module rom_async #(
    parameter WIDTH = 8,                     // data width (bits per entry)
    parameter DEPTH = 64,                    // number of entries
    parameter INIT_F = "sine_table_64x8.mem" // initialization file
)(
    input  wire [$clog2(DEPTH)-1:0] addr,    // address input
    output reg  [WIDTH-1:0] data             // data output
);

    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Initialize ROM contents from file
    initial begin
        $readmemh(INIT_F, mem);
    end

    // Asynchronous read: output changes immediately when addr changes
    always @* begin
        data = mem[addr];
    end

endmodule

`default_nettype wire
