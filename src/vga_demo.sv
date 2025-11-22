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
	


	wire Resetn = SW[0];
    wire [8:0] Color = 9'b111111111;
    wire Write = 1;

    // Testing===
    wire Refresh = SW[1];


    wire signed [nX:0] draw_X;
    wire signed [nX:0] draw_Y;

    wire screen_busy, screen_done;
    draw_screen#(.CORDW(nX+1))
        u_draw_screen (
            .clk(CLOCK_50),           
            .rstn(Resetn),
            .refresh(Refresh),
            .draw_X(draw_X),
            .draw_Y(draw_Y),
            .busy(screen_busy),
            .done(screen_done)
        );

    wire  [nX-1:0] VGA_X = draw_X[nX-1:0];
    wire  [nY-1:0] VGA_Y = draw_Y[nY-1:0];

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



    /*
    // The points to draw
    // poly 0:
    wire signed [nX:0] X00 = 10'd0;
    wire signed [nX:0] Y00 = 10'd0;

    wire signed [nX:0] X10 = 10'd400;
    wire signed [nX:0] Y10 = 10'd0;

    wire signed [nX:0] X20 = 10'd400;
    wire signed [nX:0] Y20 = 10'd400;

    wire signed [nX:0] X30 = 10'd0;
    wire signed [nX:0] Y30 = 10'd400;

    // poly 1: 左一
    wire signed [nX:0] X01 = 10'd0;
    wire signed [nX:0] Y01 = 10'd0;

    wire signed [nX:0] X11 = 10'd100;
    wire signed [nX:0] Y11 = 10'd100;

    wire signed [nX:0] X21 = 10'd100;
    wire signed [nX:0] Y21 = 10'd300;

    wire signed [nX:0] X31 = 10'd0;
    wire signed [nX:0] Y31 = 10'd400;

    // poly 3: 左二：
    wire signed [nX:0] X02 = 10'd70;
    wire signed [nX:0] Y02 = 10'd70;

    wire signed [nX:0] X12 = 10'd70;
    wire signed [nX:0] Y12 = 10'd330;

    wire signed [nX:0] X22 = 10'd100;
    wire signed [nX:0] Y22 = 10'd100;

    wire signed [nX:0] X32 = 10'd100;
    wire signed [nX:0] Y32 = 10'd300;

    // poly 3: 右一：
    wire signed [nX:0] X03 = 10'd400;
    wire signed [nX:0] Y03 = 10'd0;

    wire signed [nX:0] X13 = 10'd400;
    wire signed [nX:0] Y13 = 10'd400;

    wire signed [nX:0] X23 = 10'd330;
    wire signed [nX:0] Y23 = 10'd70;

    wire signed [nX:0] X33 = 10'd70;
    wire signed [nX:0] Y33 = 10'd330;

    // poly 4: 右二：
    wire signed [nX:0] X04 = 10'd400;
    wire signed [nX:0] Y04 = 10'd0;

    wire signed [nX:0] X14 = 10'd400;
    wire signed [nX:0] Y14 = 10'd400;

    wire signed [nX:0] X24 = 10'd330;
    wire signed [nX:0] Y24 = 10'd70;

    wire signed [nX:0] X34 = 10'd70;
    wire signed [nX:0] Y34 = 10'd330;



    wire quad_drawing, quad_busy, quad_done;
    draw_quad #(.CORDW(nX+1))
        u_draw_quad ( 
            .clk(CLOCK_50),           
            .rst(!Resetn),
            .start(quad_start),
            .oe(Write),
            .x0(ver_x0),
            .y0(ver_y0),    
            .x1(ver_x1),
            .y1(ver_y1),
            .x2(ver_x2),
            .y2(ver_y2),
            .x3(ver_x3),
            .y3(ver_y3),
            .x(draw_X),
            .y(draw_Y),
            .drawing(quad_drawing),
            .busy(quad_busy),
            .done(quad_done)
        );


// ===================================================
    // draw state machine
    


    // Internal Signal
    logic [1:0] quad_id; // current Quad ()
    logic quad_start;
    wire draw_start = SW[1];

    wire signed [nX:0] ver_x0, ver_y0, ver_x1, ver_y1, ver_x2, ver_y2, ver_x3, ver_y3; 

    enum {IDLE, INIT, DRAW} state;
    always_ff @(posedge CLOCK_50) begin
        case (state)
            INIT: begin
                state <= DRAW;
                quad_start <= 1;
                if(quad_id == 2'd0) begin
                ver_x0 <= X00; ver_y0 <= Y00;
                ver_x1 <= X10; ver_y1 <= Y10;
                ver_x2 <= X20; ver_y2 <= Y20;
                ver_x3 <= X30; ver_y3 <= Y30;
                end else if (quad_id == 2'd1) begin
                ver_x0 <= X01; ver_y0 <= Y01;
                ver_x1 <= X11; ver_y1 <= Y11;
                ver_x2 <= X21; ver_y2 <= Y21;
                ver_x3 <= X31; ver_y3 <= Y31; 
                end else if (quad_id == 2'd2) begin
                ver_x0 <= X02; ver_y0 <= Y02;
                ver_x1 <= X12; ver_y1 <= Y12;
                ver_x2 <= X22; ver_y2 <= Y22;
                ver_x3 <= X32; ver_y3 <= Y32; 
                end
            end
            DRAW: begin
                quad_start <= 0;
                LEDR = 1'b1;
                if(quad_done) begin
                    if(quad_id == 2) begin
                        state <= IDLE;
                    end else begin
                        state <= INIT;
                        quad_id <= quad_id + 1;
                    end
                end
            end
            default: begin    // IDLE
                if(draw_start) begin
                    state <= INIT;
                    quad_id <= 0;
                end
            end
        endcase

        if (!Resetn) begin
            state <= IDLE;
            quad_id <= 0;
            quad_start <= 0;
        end

    end





//========================================================
    parameter
        displace = 10'd20;
    logic signed [nX:0] X0, Y0;  // vertex 0

    always_comb begin
        X0 = draw_X + displace;
        Y0 = draw_Y + displace;
    end
*/
