`default_nettype none
`include "params.vh"

module wall_check(
    input [4:0] tile_x,   // 0..MAP_WIDTH-1
    input [4:0] tile_y,   // 0..MAP_HEIGHT-1
    output reg is_wall
);

    reg [`MAP_WIDTH-1:0] row_bits;

    always @(*) begin
        // Default: outside maze treated as wall
        is_wall  = 1'b1;
        row_bits = {`MAP_WIDTH{1'b1}};

        if (tile_y < `MAP_HEIGHT) begin
            case (tile_y)
                4'd9: row_bits = 20'b11111111111111111111; // top border
                4'd8: row_bits = 20'b10000000001111100001;
                4'd7: row_bits = 20'b10111111001000101001;
                4'd6: row_bits = 20'b10000001001000101001;
                4'd5: row_bits = 20'b11111001001110101001;
                4'd4: row_bits = 20'b10001001000010101001;
                4'd3: row_bits = 20'b10101001111110101001;
                4'd2: row_bits = 20'b10101000000000101001;
                4'd1: row_bits = 20'b10001111111110100001;
                4'd0: row_bits = 20'b11111111111111111111; // bottom border
                default: row_bits = {`MAP_WIDTH{1'b1}};
            endcase

            if (tile_x < `MAP_WIDTH)
                // col 0 = leftmost (MSB)
                is_wall = row_bits[`MAP_WIDTH-1 - tile_x];
        end
    end

endmodule