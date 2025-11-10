`include "params.vh"

module map_horizontal(
    input [3:0] addr,
    output reg [0:`MAP_WIDTH-1] data
);
    // 8*7
    always @(*)
        case (addr)
        3'd7: data = 7'b1111111;
        3'd6: data = 7'b0000000;
        3'd5: data = 7'b0000000;
        3'd4: data = 7'b0000000;
        3'd3: data = 7'b0000000;
        3'd2: data = 7'b0000000;
        3'd1: data = 7'b0000000;
        3'd0: data = 7'b1111111;
        endcase
endmodule

module map_vertical(
    input [3:0] addr,
    output reg [0:`MAP_WIDTH] data
);
    // 7*8
    always @(*)
        case (addr)
        3'd6: data = 8'b10000001;
        3'd5: data = 8'b10000001;
        3'd4: data = 8'b10000001;
        3'd3: data = 8'b10000001;
        3'd2: data = 8'b10000001;
        3'd1: data = 8'b10000001;
        3'd0: data = 8'b10000001;
        endcase
endmodule


module onchip_mem (
    input clk,
    input [9:0] addr,
    input [7:0] din,
    input we,
    output reg [7:0] dout
);
    reg [7:0] mem [0:1023];  // 1KB memory in FPGA fabric

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule
