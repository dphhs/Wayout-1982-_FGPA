`default_nettype none

/*  This code first displays a background image (MIF) on the VGA output. Then, the code
 *  displays two objects, each of which is read from a small memory, on the screen. Each
 *  object can be moved left/right/up/down by pressing PS2 keyboard keys. To use the circuit,
 *  first use KEY[0] to perform a reset. The background MIF should appear on the VGA output. 
 *  Pressing KEY[1] displays one object, at its initial position, and pressing KEY[2] displays
 *  the other object. Move the first object left/right/up/down using PS2 keys a/s/w/z, and 
 *  the other object using d/f/r/c.
*/
module vga_demo(CLOCK_50, SW, KEY, LEDR, PS2_CLK, PS2_DAT, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
				VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

    // default resolution. Specify a resolution in top.v
    parameter RESOLUTION = "640x480"; // "640x480" "320x240" "160x120"

    // default color depth. Specify a color in top.v
    parameter COLOR_DEPTH = 9; // 9 6 3

    // specify the number of bits needed for an X (column) pixel coordinate on the VGA display
    parameter nX = (RESOLUTION == "640x480") ? 11 : ((RESOLUTION == "320x240") ? 9 : 8);
    // specify the number of bits needed for a Y (row) pixel coordinate on the VGA display
    parameter nY = (RESOLUTION == "640x480") ? 10 : ((RESOLUTION == "320x240") ? 8 : 7);


	input wire CLOCK_50;	
	input wire [9:0] SW;
	input wire [3:0] KEY;
	output wire [9:0] LEDR;
    inout wire PS2_CLK, PS2_DAT;
    output wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	output wire [7:0] VGA_R;
	output wire [7:0] VGA_G;
	output wire [7:0] VGA_B;
	output wire VGA_HS;
	output wire VGA_VS;
	output wire VGA_BLANK_N;
	output wire VGA_SYNC_N;
	output wire VGA_CLK;	
	
    wire [8:0] Color;
    wire Write = 1;

    // Testing===
    wire Resetn = SW[0];
    wire PosReset = SW[1];
    wire logic signed [5:0] Px;
    wire logic signed [5:0] Py;
    wire logic [1:0] Direction;


    // Key debounce and edge detection
    reg [3:0] key_reg;        // Register to store previous key state
    reg [3:0] key_pressed;    // Single-cycle pulse output

    always @(posedge CLOCK_50) begin
        key_reg <= KEY;  // Store current key state
        key_pressed <= key_reg & ~KEY;
    end



    wire signed [nX:0] draw_X;
    wire signed [nX:0] draw_Y;

    wire Refresh;
    wire screen_busy, screen_done;
    draw_screen#(.CORDW(nX+1))
        u_draw_screen (
            .clk(CLOCK_50),           
            .rstn(Resetn),
            .refresh(Refresh),
            .px(Px),
            .py(Py),
            .direction(Direction),
            .draw_X(draw_X),
            .draw_Y(draw_Y),
            .color(Color),
            .busy(screen_busy),
            .done(screen_done)
        );

    wire  [nX-1:0] VGA_X = draw_X[nX-1:0];
    wire  [nY-1:0] VGA_Y = draw_Y[nY-1:0];



    player u_player(
        .clk(CLOCK_50),           
        .rstn(PosReset),
        .key_pressed(key_pressed),
        .refresh(Refresh),
        .px(Px),
        .py(Py),
        .direction(Direction)
    );


//===============================================================

    // connect to VGA controller
    vga_adapter VGA (
			.resetn(Resetn),
			.clock(CLOCK_50),
			.color(Color),
			.x(VGA_X),
			.y(VGA_Y),
			.write(Write),

			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK_N(VGA_BLANK_N),
			.VGA_SYNC_N(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));

endmodule
