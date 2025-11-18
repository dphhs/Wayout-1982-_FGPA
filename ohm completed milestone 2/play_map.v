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

// ============================================================
// play_map: converts screen pixel (x,y) → is_wall
// Used by VGA controller to overlay maze over background
// ============================================================
        case (addr)
		  
				 4'd9: data = 20'b11111111111111111111; // top border
				 4'd8: data = 20'b10000000001111100001;
				 4'd7: data = 20'b10111111001000101001;
				 4'd6: data = 20'b10000001001000101001;
				 4'd5: data = 20'b11111001001110101001;
				 4'd4: data = 20'b10001001000010101001;
				 4'd3: data = 20'b10101001111110101001;
				 4'd2: data = 20'b10101000000000101001;
				 4'd1: data = 20'b10001111111110100001;
				 4'd0: data = 20'b11111111111111111111; // bottom border

				 default: data = 20'b0;
        endcase
    end
endmodule

module play_map #(
    parameter CELL_SIZE = 16,
    parameter MAZE_X0   = 160,   // centered horizontally for 20 tiles
    parameter MAZE_Y0   = 320    // bottom aligned for 10 tiles
)(
    input  wire [9:0] x,
    input  wire [8:0] y,
    output wire       is_wall
);

    // Maze region: 20 × 10 tiles
    wire in_region =
        (x >= MAZE_X0) &&
        (x <  MAZE_X0 + (`MAP_WIDTH  * CELL_SIZE)) &&
        (y >= MAZE_Y0) &&
        (y <  MAZE_Y0 + (`MAP_HEIGHT * CELL_SIZE));

    // Offset inside maze region
    wire [9:0] rel_x = x - MAZE_X0;
    wire [8:0] rel_y = y - MAZE_Y0;

    // Tile coordinates (division by 16)
    wire [$clog2(`MAP_WIDTH)-1:0]  col = rel_x[9:4];   // 0..19
    wire [$clog2(`MAP_HEIGHT)-1:0] row = rel_y[8:4];   // 0..9

    // Retrieve row bits
    wire [`MAP_WIDTH-1:0] row_bits;

    map_horizontal u_row(
        .addr(row),
        .data(row_bits)
    );

    // Wall bit selection:
    // highest bit is col = 0
    wire tile_is_wall = row_bits[`MAP_WIDTH-1 - col];

    assign is_wall = in_region && tile_is_wall;

endmodule

