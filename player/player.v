`default_nettype none
`include "params.vh"

module player (
    // Board-level inputs
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,   
    input resetn,    
    output wire [9:0]  LEDR,  

    // Seven Segment Outputs
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX0,

    // Player outputs (tile coordinates + direction)
    output reg  [4:0]  x_position,
    output reg  [4:0]  y_position,
    output reg  [1:0]  dir
);

    wire clock  = CLOCK_50;
    assign LEDR = 10'b0;

    //------------------------------------------------------------
    // Decode KEYs (active-low buttons)
    // KEY[3] = left, KEY[2] = right, KEY[1] = forward, KEY[0] = backward
    //------------------------------------------------------------
    wire key_left      = ~KEY[3];
    wire key_right     = ~KEY[2];
    wire key_forward   = ~KEY[1];
    wire key_backward  = ~KEY[0];

    //------------------------------------------------------------
    // Edge detection to create 1-cycle pulses on button press
    //------------------------------------------------------------
    reg prev_left, prev_right, prev_forward, prev_backward;
    reg forward_pulse, backward_pulse, rotateA, rotateD;

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            prev_left      <= 1'b0;
            prev_right     <= 1'b0;
            prev_forward   <= 1'b0;
            prev_backward  <= 1'b0;

            forward_pulse  <= 1'b0;
            backward_pulse <= 1'b0;
            rotateA        <= 1'b0;
            rotateD        <= 1'b0;
        end
        else begin
            // store previous state
            prev_left     <= key_left;
            prev_right    <= key_right;
            prev_forward  <= key_forward;
            prev_backward <= key_backward;

            // pulses when button transitions 0 -> 1
            forward_pulse  <= key_forward  & ~prev_forward;
            backward_pulse <= key_backward & ~prev_backward;
            rotateA        <= key_left     & ~prev_left;
            rotateD        <= key_right    & ~prev_right;
				
        end
    end

    //------------------------------------------------------------
    // Collision helpers (check tile in front / behind)
    //------------------------------------------------------------
    reg [4:0] infront_of_x, above_of_y;
    reg [4:0] behind_of_x,  below_of_y;

    wire front_wall;
    wire back_wall;

    wall_check fw (
        .tile_x (infront_of_x),
        .tile_y (above_of_y),
        .is_wall(front_wall)
    );

    wall_check bw (
        .tile_x (behind_of_x),
        .tile_y (below_of_y),
        .is_wall(back_wall)
    );

    //------------------------------------------------------------
    // State registers
    //------------------------------------------------------------
    reg [4:0] next_x, next_y;
    reg [1:0] next_dir;

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x_position <= 5'd1;
            y_position <= 5'd1;
            dir        <= `DIR_EAST;
        end else begin
            x_position <= next_x;
            y_position <= next_y;
            dir        <= next_dir;
        end
    end

    // Next-state (FSM) logic (movement + rotation + collision)

    always @* begin
        next_x   = x_position;
        next_y   = y_position;
        next_dir = dir;

        // Default collision tiles equal current position
        infront_of_x = x_position;
        above_of_y   = y_position;
        behind_of_x  = x_position;
        below_of_y   = y_position;

        // Compute collision positions based on facing direction
        case (dir)
            `DIR_EAST: begin
                infront_of_x = x_position + 1;
                behind_of_x  = x_position - 1;
            end
            `DIR_WEST: begin
                infront_of_x = x_position - 1;
                behind_of_x  = x_position + 1;
            end
            `DIR_NORTH: begin
                above_of_y   = y_position - 1;
                below_of_y   = y_position + 1;
            end
            `DIR_SOUTH: begin
                above_of_y   = y_position + 1;
                below_of_y   = y_position - 1;
            end
        endcase

        // Rotation (A/D -> left/right)
        if (rotateA && !rotateD)
            next_dir = dir + 2'b01; // rotate left (cyclic)
        else if (rotateD && !rotateA)
            next_dir = dir - 2'b01; // rotate right (cyclic)

        // Forward / backward movement with wall check
        if (forward_pulse && !front_wall) begin
            next_x = infront_of_x;
            next_y = above_of_y;
        end else if (backward_pulse && !back_wall) begin
            next_x = behind_of_x;
            next_y = below_of_y;
        end
    end

    //------------------------------------------------------------
    // 7-seg display using seg7
    //------------------------------------------------------------
    wire [3:0] x_tens  = (x_position >= 10) ? 4'd1 : 4'd0;
    wire [3:0] x_ones  = (x_position >= 10) ? (x_position - 10) : x_position[3:0];
    wire [3:0] y_tens  = (y_position >= 10) ? 4'd1 : 4'd0;
    wire [3:0] y_ones  = (y_position >= 10) ? (y_position - 10) : y_position[3:0];
    wire [3:0] dir_hi  = {3'b000, dir[1]};
    wire [3:0] dir_lo  = {3'b000, dir[0]};

    seg7 s5(.C(x_tens), .Display(HEX5));
    seg7 s4(.C(x_ones), .Display(HEX4));
    seg7 s3(.C(y_tens), .Display(HEX3));
    seg7 s2(.C(y_ones), .Display(HEX2));
    seg7 s1(.C(dir_hi), .Display(HEX1));
    seg7 s0(.C(dir_lo), .Display(HEX0));

endmodule


//======================================================================
// Player drawer (same as you had)
//======================================================================
module player_drawer (
    input  wire        clock,
    input  wire        resetn,

    // Player tile position + direction
    input  wire [4:0]  player_tile_x,
    input  wire [4:0]  player_tile_y,
    input  wire [1:0]  player_dir,

    // Only draw when maze has been written
    input  wire        maze_done,

    // Write port to vga_adapter
    output reg  [9:0]  vga_x,
    output reg  [8:0]  vga_y,
    output reg  [8:0]  vga_color,
    output reg         vga_write
);

    // Colors: 9-bit RGB (RRR GGG BBB)
    localparam [8:0] PLAYER_COLOR = {3'b111, 3'b111, 3'b000}; // yellow
    localparam [8:0] FLOOR_COLOR  = 9'b000_000_000;           // black floor

    // Previous tile we drew the player on
    reg [4:0] prev_tile_x;
    reg [4:0] prev_tile_y;

    // Scan inside one tile: 0 .. CELL_SIZE-1
    reg [$clog2(`CELL_SIZE)-1:0] px;
    reg [$clog2(`CELL_SIZE)-1:0] py;

    // Phase: 0 = clear previous tile, 1 = draw current tile
    reg phase;

    // --- Pixel bases for previous and current tiles ---
    wire [9:0] base_x_prev = `MAZE_X0 + prev_tile_x    * `CELL_SIZE;
    wire [8:0] base_y_prev = `MAZE_Y0 + prev_tile_y    * `CELL_SIZE;

    wire [9:0] base_x_cur  = `MAZE_X0 + player_tile_x  * `CELL_SIZE;
    wire [8:0] base_y_cur  = `MAZE_Y0 + player_tile_y  * `CELL_SIZE;

    // Choose which tile we are currently scanning
    wire [9:0] base_x = (phase == 1'b0) ? base_x_prev : base_x_cur;
    wire [8:0] base_y = (phase == 1'b0) ? base_y_prev : base_y_cur;

    // Current pixel in world coordinates
    wire [9:0] cur_x = base_x + px;
    wire [8:0] cur_y = base_y + py;

    // Player center (for sprite calculations) uses CURRENT tile
    wire [10:0] player_px = base_x_cur + `HALF_CELL;
    wire [10:0] player_py = base_y_cur + `HALF_CELL;

    // Ask sprite logic which pixels are part of the arrow
    wire sprite_pixel;
    player_sprite #(.ARROW_SIZE(8)) SPR (
        .x        ({1'b0, cur_x}),   // 10 -> 11 bits
        .y        ({2'b00, cur_y}),  // 9  -> 11 bits
        .player_px(player_px),
        .player_py(player_py),
        .dir      (player_dir),
        .pixel_on (sprite_pixel)
    );

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            // On reset, assume previous tile = current tile
            prev_tile_x <= 5'd1;
            prev_tile_y <= 5'd1;

            px        <= 0;
            py        <= 0;
            phase     <= 1'b0;   // start by "clearing" prev tile (same as current at reset)

            vga_x     <= 10'd0;
            vga_y     <= 9'd0;
            vga_color <= 9'd0;
            vga_write <= 1'b0;

        end else if (maze_done) begin
            // Drive current pixel coords
            vga_x <= cur_x;
            vga_y <= cur_y;

            // Phase 0: clear previous tile to floor color
            // Phase 1: draw current tile with sprite or floor
            if (phase == 1'b0) begin
                vga_color <= FLOOR_COLOR;
                vga_write <= 1'b1;
            end else begin
                vga_color <= sprite_pixel ? PLAYER_COLOR : FLOOR_COLOR;
                vga_write <= 1'b1;
            end

            // Advance within the tile
            if (px == `CELL_SIZE-1) begin
                px <= 0;
                if (py == `CELL_SIZE-1) begin
                    py <= 0;

                    // Finished scanning one entire tile
                    if (phase == 1'b0) begin
                        // done clearing old tile → now draw current
                        phase <= 1'b1;
                    end else begin
                        // done drawing current tile → update prev and go back to clearing
                        prev_tile_x <= player_tile_x;
                        prev_tile_y <= player_tile_y;
                        phase       <= 1'b0;
                    end
                end else begin
                    py <= py + 1;
                end
            end else begin
                px <= px + 1;
            end

        end else begin
            // Before maze is done we don't write into VRAM
            vga_write <= 1'b0;
        end
    end

endmodule


//======================================================================
// 7-seg helper
//======================================================================
module seg7 (C, Display);

    input  [3:0] C;
    output reg [6:0] Display;
    
    always @ (*) begin
        case (C)
            4'd0:  Display = 7'b1000000;
            4'd1:  Display = 7'b1111001;
            4'd2:  Display = 7'b0100100;
            4'd3:  Display = 7'b0110000;
            4'd4:  Display = 7'b0011001;
            4'd5:  Display = 7'b0010010;
            4'd6:  Display = 7'b0000010;
            4'd7:  Display = 7'b1111000;
            4'd8:  Display = 7'b0000000;
            4'd9:  Display = 7'b0010000;
            4'd10: Display = 7'b0001000;
            4'd11: Display = 7'b0000011;
            4'd12: Display = 7'b1000110;
            4'd13: Display = 7'b0100001;
            4'd14: Display = 7'b0000110;
            4'd15: Display = 7'b0001110;
        endcase
    end

endmodule
