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


module player(
    input   wire logic clk,             // clock
    input   wire logic rstn,            // reset
    input   wire logic [3:0] key_pressed,

    output  wire logic refresh,
    // input wire logic map;
    output  wire logic signed [5:0] px,
    output  wire logic signed [5:0] py,
    output  wire logic [1:0] direction
);
    // Setting Parameter
    parameter
        H       =   13'd400,
        W       =   13'd400,

        x_width =   5,
        y_width =   5,

        displace =  13'd10,
        east    =   2'b00,
        north   =   2'b01,
        west    =   2'b10,
        south   =   2'b11;

       // Player and Map Parameter
    parameter
        row0  = 11'b11111111111,
        row1  = 11'b10001000001,
        row2  = 11'b11101010101,
        row3  = 11'b10100010101,
        row4  = 11'b10111011101,
        row5  = 11'b10001000001,
        row6  = 11'b10111001101,
        row7  = 11'b10000000001,
        row8  = 11'b10111010101,
        row9  = 11'b10100010001,
        row10 = 11'b10101000111,
        row11 = 11'b10001110001,
        row12 = 11'b10101111101,
        row13 = 11'b10100010001,
        row14 = 11'b10111010111,
        row15 = 11'b10001000101,
        row16 = 11'b11101111101,
        row17 = 11'b10001000101,
        row18 = 11'b10111010101,
        row19 = 11'b10000010001,
        row20 = 11'b11111111111,

        init_px =   5'd1,
        init_py =   5'd1;

    // Change to Input later==============
        logic [0:10] map [0:20]; // 21 rows, 11 bits each row

        // Initial Map
        always_ff @(posedge clk) begin
            if (!rstn) begin
                //px <= init_px;
                //py <= init_py;
                map[0] <= row0;
                map[1] <= row1;
                map[2] <= row2;
                map[3] <= row3;
                map[4] <= row4;
                map[5] <= row5;
                map[6] <= row6;
                map[7] <= row7;
                map[8] <= row8;
                map[9] <= row9;
                map[10] <= row10;
                map[11] <= row11;
                map[12] <= row12;
                map[13] <= row13;
                map[14] <= row14;
                map[15] <= row15;
                map[16] <= row16;
                map[17] <= row17;
                map[18] <= row18;
                map[19] <= row19;
                map[20] <= row20;
            end
        end

    assign refresh = (key_pressed[0] | key_pressed[1] | key_pressed[2] | key_pressed[3]);

    // Declare signed variables
    logic signed [5:0] forward_x, forward_y;

    // Initial Map
    always_ff @(posedge clk) begin
        if (!rstn) begin
            px <= 6'sd5;
            py <= 6'sd2;
            direction <= 2'b11;
        end else if (key_pressed[3]) begin
            direction <= direction + 1;
        end else if (key_pressed[2]) begin
            direction <= direction - 1;
        end else if (key_pressed[1]) begin
            if (map[py + forward_y][px + forward_x] == 0) begin
                px <= px + forward_x;
                py <= py + forward_y;
            end else begin
                px <= px;
                py <= py;
            end
        end else if (key_pressed[0]) begin
            if (map[py - forward_y][px - forward_x] == 0) begin
                px <= px - forward_x;
                py <= py - forward_y;
            end else begin
                px <= px;
                py <= py;
            end
        end
        // No explicit else needed - values hold by default
    end

    always_comb begin
        if (direction == east) begin
            forward_x = 1;  forward_y = 0;
        end else if (direction == north) begin
            forward_x = 0;  forward_y = -1;
        end else if (direction == west) begin
            forward_x = -1; forward_y = 0;
        end else begin  // south
            forward_x = 0;  forward_y = 1;
        end
    end

endmodule