`ifndef PARAMS_VH
`define PARAMS_VH

    `define MAP_WIDTH     20      // 20 columns
    `define MAP_HEIGHT    10      // 10 rows

    `define DATA_WIDTH    8
    `define ADDR_WIDTH    10

    `define DIR_EAST      2'b00
    `define DIR_NORTH     2'b01
    `define DIR_WEST      2'b10
    `define DIR_SOUTH     2'b11

    `define CELL_SIZE     16              // each tile = 16×16 pixels
    `define HALF_CELL     (`CELL_SIZE/2)  // tile center offset

    `define MAZE_X0       160             // left pixel of maze
    `define MAZE_Y0       320             // top pixel of maze

`endif
