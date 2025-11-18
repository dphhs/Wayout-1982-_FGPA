`default_nettype none

module wayout_top (
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,
    inout  wire        PS2_CLK,
    inout  wire        PS2_DAT,

    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,

    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire        VGA_SYNC_N,
    output wire        VGA_CLK
);

    wire resetn = KEY[0];

    // =====================================================
    // PLAYER → Provides: x_position, y_position, angle
    //           and draws through: color, x, y, write
    // =====================================================

    wire [15:0] x_position;
    wire [15:0] y_position;
    wire [1:0]  direction;

    // Pixel drawing signals from player
    wire [8:0] draw_color;
    wire [9:0] draw_x;
    wire [8:0] draw_y;
    wire       draw_write;

    player u_player (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),

        // Seven segment + LEDs
        .LEDR(LEDR),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),

        // Player coordinates
        .x_position(x_position),
        .y_position(y_position),
        .dir(direction),

        // VGA pixel output to top module
        .vga_color(draw_color),
        .vga_x(draw_x),
        .vga_y(draw_y),
        .vga_write(draw_write)
    );

    // =====================================================
    // VGA ADAPTER
    // =====================================================
	 /*	
    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),

        .color(draw_color),
        .x(draw_x),
        .y(draw_y),
        .write(draw_write),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );
	 */
	 
    vga_adapter VGA (
        .resetn(resetn),
        .clock(CLOCK_50),

        // These are ignored by vga_adapter in your current design
        .color(9'd0),
        .x(10'd0),
        .y(9'd0),
        .write(1'b0),

        // NEW: player tile coordinates + direction
        .player_tile_x(x_position),
        .player_tile_y(y_position),
        .player_dir(direction),

        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    defparam VGA.RESOLUTION = "640x480";
    defparam VGA.COLOR_DEPTH = 9;

endmodule
