`default_nettype none
`include "params.vh"

module vga_controller (
    vga_clock, resetn, pixel_color, memory_address,
    VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N,
    VGA_SYNC_N, VGA_CLK,
    player_x, player_y, player_dir
);

    // VGA parameters
    parameter RESOLUTION  = "640x480";
    parameter COLOR_DEPTH = 9;
    parameter Mn = 19;
    localparam BITS_PER_RGB = COLOR_DEPTH / 3;

    // Inputs
    input vga_clock, resetn;
    input [COLOR_DEPTH-1:0] pixel_color;   // background pixel from ROM
    input [4:0] player_x;                  // tile coordinate (0–19)
    input [4:0] player_y;                  // tile coordinate (0–19)
    input [1:0] player_dir;

    // Outputs
    output reg [7:0] VGA_R, VGA_G, VGA_B;
    output reg VGA_HS;
    output reg VGA_VS;
    output reg VGA_BLANK_N;
    output     VGA_SYNC_N;
    output     VGA_CLK;
    output wire [Mn-1:0] memory_address;

    // Direction constants (from params.vh)
    localparam DIR_EAST  = `DIR_EAST;
    localparam DIR_NORTH = `DIR_NORTH;
    localparam DIR_WEST  = `DIR_WEST;
    localparam DIR_SOUTH = `DIR_SOUTH;

    // Colors
    localparam [COLOR_DEPTH-1:0] PLAYER_COLOR = {3'b111, 3'b111, 3'b000};
    localparam [COLOR_DEPTH-1:0] WALL_COLOR   = {3'b111, 3'b000, 3'b000};

    //------------------------------------------------------------
    // Pixel mapping (fixed-width 11-bit pixel coordinates)
    //------------------------------------------------------------
    localparam integer CELL_SIZE = `CELL_SIZE;
    localparam integer HALF      = `HALF_CELL;
    localparam integer MAZE_X0   = `MAZE_X0;
    localparam integer MAZE_Y0   = `MAZE_Y0;

    // *** FIXED: Always 11-bit pixel coordinates ***
    wire [10:0] player_px = MAZE_X0 + (player_x * CELL_SIZE) + HALF;
    wire [10:0] player_py = MAZE_Y0 + (player_y * CELL_SIZE) + HALF;

    //------------------------------------------------------------
    // VGA timing counters
    //------------------------------------------------------------
    wire [9:0] h_count;
    wire [9:0] v_count;
    wire enable_vertical_tick;

    horizontal_clock h_counter (vga_clock, resetn, h_count, enable_vertical_tick);
    vertical_clock   v_counter (vga_clock, resetn, v_count, enable_vertical_tick);

    // *** FIXED: x,y must be 11 bits (match pixel space up to 640/480)
    reg [10:0] x;
    reg [10:0] y;

    always @* begin
        x = h_count;
        y = v_count;
    end
	 
	 wire arrow_pixel;

	 player_sprite #(.ARROW_SIZE(8)) sprite (
		 .x(x),
		 .y(y),
		 .player_px(player_px),
		 .player_py(player_py),
		 .dir(player_dir),
		 .pixel_on(arrow_pixel)
	 );


    //------------------------------------------------------------
    // Maze rendering (walls)
    //------------------------------------------------------------
    wire wall_pixel;

    play_map #(
        .CELL_SIZE(CELL_SIZE),
        .MAZE_X0(MAZE_X0),
        .MAZE_Y0(MAZE_Y0)
    ) maze (
        .x(x),
        .y(y),
        .is_wall(wall_pixel)
    );

    //------------------------------------------------------------
    // Final pixel (priority order)
    //------------------------------------------------------------
    wire [COLOR_DEPTH-1:0] final_color =
        arrow_pixel ? PLAYER_COLOR :
        wall_pixel  ? WALL_COLOR  :
                      pixel_color;

    //------------------------------------------------------------
    // Sync + blanking generation
    //------------------------------------------------------------
    reg VGA_HS1, VGA_VS1, VGA_BLANK1;

    always @(posedge vga_clock or negedge resetn) begin
        if (!resetn) begin
            VGA_HS1     <= 1'b1;
            VGA_VS1     <= 1'b1;
            VGA_BLANK1  <= 1'b0;

            VGA_HS      <= 1'b1;
            VGA_VS      <= 1'b1;
            VGA_BLANK_N <= 1'b0;

        end else begin
            VGA_HS1    <= ~((h_count >= 659) && (h_count <= 754));
            VGA_VS1    <= ~((v_count >= 493) && (v_count <= 494));
            VGA_BLANK1 <= ((h_count < 640) && (v_count < 480));

            VGA_HS      <= VGA_HS1;
            VGA_VS      <= VGA_VS1;
            VGA_BLANK_N <= VGA_BLANK1;
        end
    end

    assign VGA_SYNC_N = 1'b1;
    assign VGA_CLK    = vga_clock;

    //------------------------------------------------------------
    // Background ROM address translation
    //------------------------------------------------------------
    vga_address_translator controller_translator(
        .x(x),
        .y(y),
        .mem_address(memory_address)
    );
    defparam controller_translator.nX = 10;
    defparam controller_translator.nY = 9;
    defparam controller_translator.Mn = Mn;

    //------------------------------------------------------------
    // 9-bit → 24-bit RGB DAC
    //------------------------------------------------------------
    wire on_screen = (h_count < 640) && (v_count < 480);

    integer i, j;
    always @* begin
        VGA_R = 8'b0;
        VGA_G = 8'b0;
        VGA_B = 8'b0;

        for (i = 8 - BITS_PER_RGB; i >= 0; i = i - BITS_PER_RGB) begin
            for (j = BITS_PER_RGB - 1; j >= 0; j = j - 1) begin
                VGA_R[j + i] = on_screen & final_color[j + (BITS_PER_RGB * 2)];
                VGA_G[j + i] = on_screen & final_color[j + (BITS_PER_RGB * 1)];
                VGA_B[j + i] = on_screen & final_color[j + (BITS_PER_RGB * 0)];
            end
        end
    end

endmodule


//------------------------------------------------------------
// Horizontal Counter
//------------------------------------------------------------
module horizontal_clock(vga_clock, resetn, h_count, enable_vertical_tick);
    input  vga_clock, resetn;
    output reg [9:0] h_count;
    output reg       enable_vertical_tick;

    always @(posedge vga_clock) begin
        if (!resetn) begin
            h_count <= 10'd0;
            enable_vertical_tick <= 1'b0;
        end else begin
            if (h_count < 10'd799) begin
                h_count <= h_count + 1;
                enable_vertical_tick <= 1'b0;
            end else begin
                h_count <= 10'd0;
                enable_vertical_tick <= 1'b1;
            end
        end
    end
endmodule


//------------------------------------------------------------
// Vertical Counter
//------------------------------------------------------------
module vertical_clock(vga_clock, resetn, v_count, enable_vertical_tick);
    input  vga_clock, resetn, enable_vertical_tick;
    output reg [9:0] v_count = 10'd0;

    always @(posedge vga_clock) begin
        if (!resetn) begin
            v_count <= 10'd0;
        end else if (enable_vertical_tick) begin
            if (v_count < 10'd524)
                v_count <= v_count + 1;
            else
                v_count <= 10'd0;
        end
    end
endmodule
