module vga_controller (vga_clock, resetn, pixel_color, memory_address, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK, player_x, player_y);

	//Parameters
	// The VGA resolution, which can be set to "640x480", "320x240", and "160x120"
   parameter RESOLUTION = "640x480";
	parameter COLOR_DEPTH = 9;          // color depth for the video memory
   parameter nX = 10, nY = 9, Mn = 19;  // default bit widths
   parameter COLS = 640, ROWS = 480;   // default COLS x ROWS memory
	localparam BITS_PER_RGB = COLOR_DEPTH /3 ;
	 

	//Input
	input vga_clock, resetn;
	input [COLOR_DEPTH-1:0] pixel_color;
	input [nX-1:0] player_x;
	input [nY-1:0] player_y;
	
	//Output
	output reg [7:0] VGA_R, VGA_G, VGA_B;
	output reg VGA_HS;
	output reg VGA_VS;
	output reg VGA_BLANK_N;
	output     VGA_SYNC_N;
	output     VGA_CLK;
	output wire [Mn-1:0] memory_address;
	

	//Wire for horizontal_clock
	wire [9:0] h_count;
	wire enable_vertical_tick;
	
	//Wire for vertical_clock
	wire [9:0] v_count;
	
	//Reg
	reg [nX-1:0] x; 
	reg [nY-1:0] y;	
    
	// Timing parameters:
	/* The VGA specification requires that a few more rows and columns are drawn
	 * than are actually present on the screen. This is necessary to generate the vertical
     * and horizontal syncronization signals.  */
	parameter C_VERT_NUM_PIXELS  = 11'd480;
	parameter C_VERT_SYNC_START  = 11'd493;
	parameter C_VERT_SYNC_END    = 11'd494; //(C_VERT_SYNC_START + 2 - 1); 
	parameter C_VERT_TOTAL_COUNT = 11'd525;

	parameter C_HORZ_NUM_PIXELS  = 11'd640;
	parameter C_HORZ_SYNC_START  = 11'd659;
	parameter C_HORZ_SYNC_END    = 11'd754; //(C_HORZ_SYNC_START + 96 - 1); 
	parameter C_HORZ_TOTAL_COUNT = 11'd800;	
	
	//Instantiate modules
	horizontal_clock h_counter (vga_clock, resetn, h_count, enable_vertical_tick);
	vertical_clock v_counter (vga_clock, resetn, v_count, enable_vertical_tick);
	
	always @* begin
	  x = h_count[9:0]; // 0..639
	  y = v_count[8:0]; // 0..479
	end

	// -------------------------
	// Maze overlay (play_map)
	// -------------------------
	wire wall_pixel;

	play_map #(
		 .CELL_SIZE(16),
		 .MAZE_X0(80),    // centered horizontally
		 .MAZE_Y0(288)    // stuck to bottom of screen
	) maze (
		 .x(x),           // current pixel x
		 .y(y),           // current pixel y
		 .is_wall(wall_pixel)
	);	
		
	// Example wall color: bright red (for COLOR_DEPTH = 9 -> 3 bits per channel)
	localparam [COLOR_DEPTH-1:0] WALL_COLOR = {3'b111, 3'b000, 3'b000};

	// Final color: maze wall on top of background pixel_color
	wire [COLOR_DEPTH-1:0] final_color =
		wall_pixel ? WALL_COLOR : pixel_color;
	
	//H and V sync
	reg VGA_HS1, VGA_VS1, VGA_BLANK1;
	
	always @(posedge vga_clock or negedge resetn) begin
	  if (!resetn) begin
		 VGA_HS1    <= 1'b1;
		 VGA_VS1    <= 1'b1;
		 VGA_BLANK1 <= 1'b0;

		 VGA_HS     <= 1'b1;
		 VGA_VS     <= 1'b1;
		 VGA_BLANK_N<= 1'b0;
	  end else begin
		 // Same timing windows the exampleGA_ uses
		 VGA_HS1    <= ~((h_count >= 10'd659) && (h_count <= 10'd754));
		 VGA_VS1    <= ~((v_count >= 10'd493) && (v_count <= 10'd494));

		 // Visible region
		 VGA_BLANK1 <=  ((h_count <  10'd640) && (v_count <  10'd480));

		 // 1-cycle register like the example
		 VGA_HS     <= VGA_HS1;
		 VGA_VS     <= VGA_VS1;
		 VGA_BLANK_N<= VGA_BLANK1;
	  end
	end

	assign VGA_SYNC_N = 1'b1;       // constant high
	assign VGA_CLK    = vga_clock;  // forward 25 MHz pixel clock
	
	
	/* Change the (x,y) coordinate into a memory address. */
	vga_address_translator controller_translator(.x(x), .y(y), .mem_address(memory_address));
		defparam controller_translator.nX = nX;
		defparam controller_translator.nY = nY;
		defparam controller_translator.Mn = Mn;

	
	wire on_screen = (h_count < 10'd640) && (v_count < 10'd480);

	integer i, j;
	always @* begin
	  VGA_R = 8'b0;
	  VGA_G = 8'b0;
	  VGA_B = 8'b0;

	  // Replicate BITS_PER_RGB across 8-bit DACs
	  for (i = 8 - BITS_PER_RGB; i >= 0; i = i - BITS_PER_RGB) begin
		 for (j = BITS_PER_RGB - 1; j >= 0; j = j - 1) begin
			VGA_R[j + i] = on_screen & final_color[j + BITS_PER_RGB*2];
			VGA_G[j + i] = on_screen & final_color[j + BITS_PER_RGB*1];
			VGA_B[j + i] = on_screen & final_color[j + 0];
		 end
	  end
	end
	
endmodule


module horizontal_clock(vga_clock, resetn, h_count, enable_vertical_tick);

	//Input
	input vga_clock;
	input resetn;
	
	//Output
	output reg [9:0] h_count; //Total # of pixels = 800 separated: (640 - visible) + (16 - front porch) + (96 - sync pulse) + (18 - back porch)
	output reg enable_vertical_tick;
	
	
	always @ (posedge vga_clock)
	begin
	
		if(!resetn) begin 
		h_count <= 10'd0;
		enable_vertical_tick <= 1'd0;
		end
		
		else begin 
			if(h_count < 10'd799) begin //Count up to 798
				h_count <= h_count + 1;
				enable_vertical_tick <= 1'b0;
			end
				
			else begin								//At 799 we reset and increment enable_veritcal_tick
				h_count <= 10'd0;
				enable_vertical_tick <= 1'b1;
			end
		end
	end
			
endmodule
	
	
module vertical_clock(vga_clock, resetn, v_count, enable_vertical_tick);

	//Input
	input vga_clock;
	input resetn;
	input enable_vertical_tick;
	
	//Output
	output reg [9:0] v_count = 10'd0; //Total # of pixels = 525 separated: (480 - visible) + (10- front porch) + (2 - sync pulse) + (33 - back porch)
	
	always @ (posedge vga_clock)
	begin
		
		if(!resetn) begin
			v_count <= 10'd0;
		end
	
		else begin
		
			if(enable_vertical_tick == 1'b1) begin 	//Count up to 525 (0 - 524)
				if(v_count < 10'd524) 
					v_count <= v_count + 1;
				else 									//v_count == 10'd524 so we have to reset it at that last tick
					v_count <= 10'd0;	
			end
			
			else 									//At 799 we reset and increment enable_veritcal_tick
				v_count <= v_count;
			
		 end
				
	end
			
endmodule
	
	