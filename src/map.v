`include "params.vh"

module maze_map(
    input [3:0] addr,
    output reg [0:`MAP_WIDTH-1] data
);
    // 8*7
    always @(*)
        case (addr)
        4'd0: data = 21'b111111111111111111111;
        4'd1: data = 21'b

        4'd11: data = 21'b111111111111111111111;
        endcase
endmodule


