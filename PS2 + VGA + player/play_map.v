`default_nettype none
`include "params.vh"

// ============================================================
// 30 × 12 Maze Bitmap (horizontal rows)
// Each row is MAP_WIDTH bits wide (default 30 bits)
// ============================================================
module map_horizontal(
    input  wire [3:0] addr,                 // row index: 0..11
    output reg  [`MAP_WIDTH-1:0] data       // row bits: [29:0]
);
    always @(*) begin
        case (addr)
            4'd11: data = 30'b111111111111111111111111111111;
            4'd10: data = 30'b100000000000000000000000000001;
            4'd9 : data = 30'b100000000000000000000000000001;
            4'd8 : data = 30'b100000000000111100000000000001;
            4'd7 : data = 30'b100000000000111100000000000001;
            4'd6 : data = 30'b100000000000000000000000000001;
            4'd5 : data = 30'b100000011110000001111000000001;
            4'd4 : data = 30'b100000011110000001111000000001;
            4'd3 : data = 30'b100000000000000000000000000001;
            4'd2 : data = 30'b100000000000000000000000000001;
            4'd1 : data = 30'b100000000000000000000000000001;
            4'd0 : data = 30'b111111111111111111111111111111;
            default: data = 30'b0;
        endcase
    end
endmodule

// ============================================================
// play_map: converts screen pixel (x,y) → is_wall
// Used by VGA controller to overlay maze over background
// ============================================================
module play_map #(
    parameter CELL_SIZE = 16,   // each tile = 16×16 pixels
    parameter MAZE_X0   = 64,   // draw maze starting at screen X=64
    parameter MAZE_Y0   = 64    // draw maze starting at screen Y=64
)(
    input  wire [9:0] x,        // current VGA pixel X
    input  wire [8:0] y,        // current VGA pixel Y
    output wire       is_wall   // 1 = this pixel should be a wall
);
    // Is (x,y) inside the rectangular area of the maze?
    wire in_region =
        (x >= MAZE_X0) &&
        (x <  MAZE_X0 + 30 * CELL_SIZE) &&
        (y >= MAZE_Y0) &&
        (y <  MAZE_Y0 + 12 * CELL_SIZE);

    // Convert VGA pixel → tile coordinate
    wire [9:0] rel_x = x - MAZE_X0;
    wire [8:0] rel_y = y - MAZE_Y0;

    wire [4:0] col = rel_x[9:4];    // divide by 16 → 0..29
    wire [3:0] row = rel_y[8:4];    // divide by 16 → 0..11

    // One 30-bit row from map
    wire [`MAP_WIDTH-1:0] row_bits;

    map_horizontal u_row(
        .addr(row),
        .data(row_bits)
    );

    // Extract whether this tile is a wall
	 wire tile_is_wall = row_bits[`MAP_WIDTH-1 - col];


    // Final output
    assign is_wall = in_region && tile_is_wall;
	 
endmodule
