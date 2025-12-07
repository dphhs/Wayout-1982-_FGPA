module play_map #(
    parameter CELL_SIZE = `CELL_SIZE,
    parameter MAZE_X0   = `MAZE_X0,   // top-left pixel of maze
    parameter MAZE_Y0   = `MAZE_Y0
)(
    input  wire [9:0] x,      // pixel x
    input  wire [8:0] y,      // pixel y
    output wire       is_wall
);

    // Maze region: MAP_WIDTH × MAP_HEIGHT tiles
    wire in_region =
        (x >= MAZE_X0) &&
        (x <  MAZE_X0 + (`MAP_WIDTH  * CELL_SIZE)) &&
        (y >= MAZE_Y0) &&
        (y <  MAZE_Y0 + (`MAP_HEIGHT * CELL_SIZE));

    // Offset inside maze region (pixels)
    wire [9:0] rel_x = x - MAZE_X0;
    wire [8:0] rel_y = y - MAZE_Y0;

    // Tile coordinates (divide by CELL_SIZE = 16 → use top bits)
    wire [$clog2(`MAP_WIDTH)-1:0]  col = rel_x[9:4];  // 0..10
    wire [$clog2(`MAP_HEIGHT)-1:0] row = rel_y[8:4];  // 0..20

    // Retrieve row bits from map_horizontal
    wire [`MAP_WIDTH-1:0] row_bits;

    map_horizontal u_row (
        .addr(row),
        .data(row_bits)
    );

    // Wall bit selection: highest bit = col 0 (leftmost)
    wire tile_is_wall = row_bits[`MAP_WIDTH-1 - col];

    assign is_wall = in_region && tile_is_wall;

endmodule
