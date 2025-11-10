module vga(SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, KEY, CLOCK_50, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);

	//Input
	input [9:0] SW;
	input CLOCK_50;
	input [3:0] KEY;
	
	//Output
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output [9:0] LEDR;
	output [7:0] VGA_R, VGA_G, VGA_B;
	output VGA_HS, VGA_VS;
	
	//Add adapter part
	output VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;
	
	//Wire
	wire resetn = ~KEY[0];
	wire vga_clock;
	
	//Wire for horizontal_clock
	wire [9:0] h_count;
	wire enable_vertical_tick;
	
	//Wire for vertical_clock
	wire [9:0] v_count;
	
	//Instantiate modules
	VGA_CLOCK make_vga_clock (CLOCK_50, resetn, vga_clock);
	horizontal_clock h_counter (vga_clock, resetn, h_count, enable_vertical_tick);
	vertical_clock v_counter (vga_clock, resetn, v_count, enable_vertical_tick);
	
	//H and V sync
	assign VGA_HS = ~(h_count >= 10'd656 && h_count < 10'd752);
	assign VGA_VS = ~(v_count >= 10'd490 && v_count < 10'd492);

	//Colors
	//assign VGA_R = 8'hF & (h_count < 10'd784) & (h_count > 10'd143) & (v_count < 10'd515) & (v_count > 10'd35);
	//assign VGA_G = 8'hF & (h_count < 10'd784) & (h_count > 10'd143) & (v_count < 10'd515) & (v_count > 10'd35);
	//assign VGA_B = 8'hF & (h_count < 10'd784) & (h_count > 10'd143) & (v_count < 10'd515) & (v_count > 10'd35);
	
	// visible window
	//wire active = (h_count < 10'd640) && (v_count < 10'd480);

	// simple white screen
	//assign VGA_R = {8{active}};
	//assign VGA_G = {8{active}};
	//assign VGA_B = {8{active}};
	
	
	//We will make a 320x240 resolution and then SCALE BY 2 to make 640x480
	localparam integer scale = 2;
	localparam integer columns = 320;
	localparam integer rows = 240;
	localparam integer bits_per_pixel = 9;
	
	
	
	//dual_port_ram vga_memory (.clock_a(CLOCK_50), .clock_b(vga_clock), 
	
	/**
	  // Create the dual-port video memory
    altsyncram VideoMemory (
        .wren_a (writeEn),      // write enable for port a
        .wren_b (gnd),          // write enable for port b
        .clock0 (clock),        // write clock
        .clock1 (clock_25),     // VGA (read) clock
        .clocken0 (vcc),        // write enable clock
        .clocken1 (vcc),        // read enable clock                
        .address_a (user_to_video_memory_addr),
        .address_b (controller_to_video_memory_addr),
        .data_a (color),        // data in from user
        .q_b (to_ctrl_color)    // data out to controller
    );
    defparam
        VideoMemory.width_a = (COLOR_DEPTH),
        VideoMemory.width_b = (COLOR_DEPTH),
        VideoMemory.intended_device_family = "Cyclone V",
        VideoMemory.operation_mode = "DUAL_PORT",
        VideoMemory.widthad_a = (Mn),
        VideoMemory.numwords_a = (COLS * ROWS),
        VideoMemory.widthad_b = (Mn),
        VideoMemory.numwords_b = (COLS * ROWS),
        VideoMemory.outdata_reg_b = "CLOCK1",
        VideoMemory.address_reg_b = "CLOCK1",
        VideoMemory.clock_enable_input_a = "BYPASS",
        VideoMemory.clock_enable_input_b = "BYPASS",
        VideoMemory.clock_enable_output_b = "BYPASS",
        VideoMemory.power_up_uninitialized = "FALSE",
        VideoMemory.init_file = BACKGROUND_IMAGE;
	**/



endmodule


		///640 × 480 @ 60 Hz (VGA standard)///
		///640 × 480 @ 60 Hz (VGA standard)///

		
		
module VGA_CLOCK (CLOCK_50, resetn, vga_clock);
	
	//Input
	input CLOCK_50;
	input resetn;
	
	//Output 
	output reg vga_clock;
	
	always @ (posedge CLOCK_50 or negedge resetn)
	begin
	
		if(!resetn)
			vga_clock <= 1'b0;
		
		else
			vga_clock <= ~vga_clock;
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
	
	