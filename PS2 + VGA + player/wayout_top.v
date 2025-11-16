`default_nettype none

module wayout_top (
	
	input CLOCK_50,
	input [0:0] KEY,
	inout wire PS2_CLK, PS2_DAT,
	
	output [9:0] LEDR,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	
	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output VGA_HS,
	output VGA_VS,
	output VGA_BLANK_N,
	output VGA_SYNC_N,
	output VGA_CLK
);

	wire resetn;
	assign resetn = KEY[0];
	
	wire [15:0] x_position;
	wire [15:0] y_position;
	wire [8:0] angle;
	
	player_control_top(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.LEDR(LEDR),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.HEX4(HEX4),
		.HEX5(HEX5),
		.x_position(x_position),
		.y_position(y_position),
		.angle(angle),
);

	wire [7:0] player_xpos_int = x_position[15:8];
	wire [7:0] player_ypos_int = y_position[15:8];
	
	wire [9:0] display_x = {2'b0, player_xpos_int};
	wire [8:0] display_y = {1'b1, player_ypos_int};
	
	
	// 3) VGA adapter instance (640x480 mode)
	wire [8:0] color = 9'd0;

	vga_adapter VGA (
		 .resetn      (resetn),
		 .clock       (CLOCK_50),
		 .color       (color),
		 .x           (display_x),
		 .y           (display_y),
		 .write        (1'b0),         // or .write depending on your adapter file
		 .VGA_R       (VGA_R),
		 .VGA_G       (VGA_G),
		 .VGA_B       (VGA_B),
		 .VGA_HS      (VGA_HS),
		 .VGA_VS      (VGA_VS),
		 .VGA_BLANK_N (VGA_BLANK_N),
		 .VGA_SYNC_N  (VGA_SYNC_N),
		 .VGA_CLK     (VGA_CLK)
	);
	defparam VGA.RESOLUTION               = "640x480";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	// defparam VGA.BACKGROUND_IMAGE      = "some_image_640_9.mif";

endmodule
		
		
		
		
		
		
		
		