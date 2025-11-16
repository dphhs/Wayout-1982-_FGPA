module framebuffer #(
    parameter WIDTH = 320,
    parameter HEIGHT = 240,
    parameter DATAW = 1
)(
    input  logic clk,
    // Write interface
    input  logic we,
    input  logic [$clog2(WIDTH*HEIGHT)-1:0] addr_write,
    input  logic [DATAW-1:0] data_in,
    // Read interface
    input  logic [$clog2(WIDTH*HEIGHT)-1:0] addr_read,
    output logic [DATAW-1:0] data_out
);
    localparam DEPTH = WIDTH*HEIGHT;
    logic [DATAW-1:0] mem [0:DEPTH-1];
    
    // Synchronous write, registered read (BRAM-friendly)
    always_ff @(posedge clk) begin
        if (we)
            mem[addr_write] <= data_in;
        data_out <= mem[addr_read];
    end
endmodule

