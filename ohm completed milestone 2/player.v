	`default_nettype none
	`include "params.vh"

	module player (
		 // Board-level inputs
		 input  wire        CLOCK_50,
		 input  wire [0:0]  KEY,
		 inout  wire        PS2_CLK,
		 inout  wire        PS2_DAT,

		 // Board-level outputs
		 output wire [9:0]  LEDR,   // from ps2controller (Total keypresses)

		 // Seven-seg displays
		 output reg  [6:0]  HEX5,   // X tens
		 output reg  [6:0]  HEX4,   // X ones
		 output reg  [6:0]  HEX3,   // Y tens
		 output reg  [6:0]  HEX2,   // Y ones
		 output reg  [6:0]  HEX1,   // dir[1] as 0/1
		 output reg  [6:0]  HEX0,   // dir[0] as 0/1

		 // Player outputs (5-bit coords)
		 output reg  [4:0]  x_position,   // 0–19
		 output reg  [4:0]  y_position,   // 0–19
		 output reg  [1:0]  dir,           // 2-bit direction (00=E,01=N,10=W,11=S)
		 output [8:0] vga_color,
		 output [9:0] vga_x,		
		 output [8:0] vga_y,
		 output vga_write
		 
	);

		 //===========================================================
		 // Local clock/reset wires
		 //===========================================================
		 wire clock  = CLOCK_50;
		 wire resetn = KEY[0];

		 // PS/2 wires from controller into player logic
		 wire [7:0] scancode;
		 wire       scancode_valid;

		 //===========================================================
		 // Instantiate PS/2 controller
		 //===========================================================
		 ps2controller u_ps2 (
			  .CLOCK_50       (CLOCK_50),
			  .KEY            (KEY),
			  .PS2_CLK        (PS2_CLK),
			  .PS2_DAT        (PS2_DAT),

			  .LEDR           (LEDR),

			  // Ignore HEX outputs from ps2controller
			  .HEX0           (),
			  .HEX1           (),
			  .HEX2           (),
			  .HEX3           (),
			  .HEX4           (),
			  .HEX5           (),

			  .scancode_out   (scancode),
			  .scancode_valid (scancode_valid)
		 );
		 
		 //Input valid every second
		 reg [25:0] internal_clock = 26'd0;
		 reg accept_tick = 1'b0;
		 wire move_made = forward_pulse | backward_pulse | rotateA | rotateD;
		 
		 always @ (posedge clock or negedge resetn) begin
			if(!resetn) begin
				internal_clock <= 26'd0;
				accept_tick <= 1'b1;
			end
			else begin
				if(move_made == 1'b1) begin
					internal_clock <= 26'd0;
					accept_tick <= 1'b0;
				end
				
				else //move_made == 0 so no moves has been made yet
					if(internal_clock >= 26'd24_999_999)
						accept_tick <= 1'b1;
					else
						internal_clock <= internal_clock + 26'd1;
			end
		end		
			
		 reg release_flag;
		 reg forward_pulse, backward_pulse, rotateA, rotateD;
		 /*
		 always @ (posedge clock or negedge resetn) begin
			if(!resetn) begin
				release_flag <= 1'd0;
				forward_pulse <= 1'd0;
				backward_pulse <= 1'd0;
				rotateA <= 1'd0;
				rotateD <= 1'd0;
			end
			
			else begin
				forward_pulse <= 1'd0;
				backward_pulse <= 1'd0;
				rotateA <= 1'd0;
				rotateD <= 1'd0;
				
				if(scancode_valid) begin
					if(scancode == 8'hF0) 
						release_flag <= 1'b1;
					else if(release_flag == 1'b1)
						release_flag <= 1'b0;
				end
				
				else if (accept_tick == 1'b1) begin
					case (scancode)
                    8'h1D: begin // W
                        forward_pulse <= 1'b1;
                    end
                    8'h1B: begin // S
                        backward_pulse <= 1'b1;
                    end
                    8'h1C: begin // A
                        rotateA  <= 1'b1;
                    end
                    8'h23: begin // D
                        rotateD <= 1'b1;
                    end
                    default: ;
                endcase
				end
			end
		end
		*/
		always @ (posedge clock or negedge resetn) begin
    if (!resetn) begin
        release_flag    <= 1'b0;
        forward_pulse   <= 1'b0;
        backward_pulse  <= 1'b0;
        rotateA         <= 1'b0;
        rotateD         <= 1'b0;
    end
    else begin
        // default pulses cleared
        forward_pulse   <= 1'b0;
        backward_pulse  <= 1'b0;
        rotateA         <= 1'b0;
        rotateD         <= 1'b0;

        if(scancode_valid) begin

            if (scancode == 8'hF0) begin
                release_flag <= 1'b1;
            end

            else if (release_flag) begin
                release_flag <= 1'b0; // ignore release
            end

            else if (accept_tick) begin
                case (scancode)
                    8'h1D: forward_pulse  <= 1'b1; // W
                    8'h1B: backward_pulse <= 1'b1; // S
                    8'h1C: rotateA        <= 1'b1; // A
                    8'h23: rotateD        <= 1'b1; // D
                    default: ;
                endcase
            end
        end
    end
end

		
		 //===========================================================
		 // PLAYER REGISTER + UPDATE FSM
		 //===========================================================
		 reg [4:0] next_x, next_y;
		 reg [1:0] next_dir;

		 // ----------------------------------------------
		 //Do collision detection
		 reg [4:0] infront_of_x, above_of_y; //tile in front of player
		 reg [4:0] behind_of_x, below_of_y;	 //tile behind the player
		 wire front_wall;       // 1 if wall in front
		 wire back_wall;

		 // Wall check module instantiation
		 wall_check f_wall (						//CHECK THE FRONT WALL
			 .tile_x(infront_of_x),
			 .tile_y(above_of_y),
			 .is_wall(front_wall)
		);
		
		wall_check b_wall (
			 .tile_x(behind_of_x),
			 .tile_y(below_of_y),
			 .is_wall(back_wall)
		);

		 
		 always @(posedge clock or negedge resetn) begin
			  if (!resetn) begin
					x_position <= 5'd1;        // starting tile
					y_position <= 5'd1;
					dir        <= `DIR_EAST;    // facing east
			  end
			  else begin
					x_position <= next_x;
					y_position <= next_y;
					dir        <= next_dir;
			  end
		 end

	// FSM UPDATE LOGIC (with forward wall collision)
	
	always @* begin
		 next_x   = x_position;
		 next_y   = y_position;
		 next_dir = dir;

		 // compute tiles
		 infront_of_x = x_position;
		 above_of_y   = y_position;
		 behind_of_x  = x_position;
		 below_of_y   = y_position;

		 case (dir)
			  `DIR_EAST: begin
					infront_of_x = x_position + 5'd1;
					behind_of_x  = x_position - 5'd1;
			  end
			  `DIR_WEST: begin
					infront_of_x = x_position - 5'd1;
					behind_of_x  = x_position + 5'd1;
			  end
			  `DIR_NORTH: begin
					above_of_y   = y_position - 5'd1;
					below_of_y   = y_position + 5'd1;
			  end
			  `DIR_SOUTH: begin
					above_of_y   = y_position + 5'd1;
					below_of_y   = y_position - 5'd1;
			  end
		 endcase

		 // rotation (same as you had)
		 if (rotateA && !rotateD)
			  next_dir = dir + 2'b01;
		 else if (rotateD && !rotateA)
			  next_dir = dir - 2'b01;

		 // movement with collision
		 if (forward_pulse && !front_wall) begin
			  next_x = infront_of_x;
			  next_y = above_of_y;
		 end else if (backward_pulse && !back_wall) begin
			  next_x = behind_of_x;
			  next_y = below_of_y;
		 end
	end




		 //===========================================================
		 // 7-SEG DISPLAY LOGIC
		 //===========================================================
		 reg [3:0] x_tens, x_ones;
		 reg [3:0] y_tens, y_ones;
		 reg [3:0] dir_msb_digit, dir_lsb_digit;

		 always @* begin
			  // X in [0..19]
			  if (x_position >= 5'd10) begin
					x_tens = 4'd1;
					x_ones = x_position - 5'd10;
			  end else begin
					x_tens = 4'd0;
					x_ones = x_position[3:0];
			  end

			  // Y in [0..19]
			  if (y_position >= 5'd10) begin
					y_tens = 4'd1;
					y_ones = y_position - 5'd10;
			  end else begin
					y_tens = 4'd0;
					y_ones = y_position[3:0];
			  end

			  // Direction bits as decimal digits 0 or 1
			  dir_msb_digit = {3'b000, dir[1]}; // HEX1
			  dir_lsb_digit = {3'b000, dir[0]}; // HEX0

			  // HEX5 - x_tens
			  case (x_tens)
					4'd0: HEX5 = 7'b1000000;
					4'd1: HEX5 = 7'b1111001;
					4'd2: HEX5 = 7'b0100100;
					4'd3: HEX5 = 7'b0110000;
					4'd4: HEX5 = 7'b0011001;
					4'd5: HEX5 = 7'b0010010;
					4'd6: HEX5 = 7'b0000010;
					4'd7: HEX5 = 7'b1111000;
					4'd8: HEX5 = 7'b0000000;
					4'd9: HEX5 = 7'b0010000;
					default: HEX5 = 7'b1111111;
			  endcase

			  // HEX4 - x_ones
			  case (x_ones)
					4'd0: HEX4 = 7'b1000000;
					4'd1: HEX4 = 7'b1111001;
					4'd2: HEX4 = 7'b0100100;
					4'd3: HEX4 = 7'b0110000;
					4'd4: HEX4 = 7'b0011001;
					4'd5: HEX4 = 7'b0010010;
					4'd6: HEX4 = 7'b0000010;
					4'd7: HEX4 = 7'b1111000;
					4'd8: HEX4 = 7'b0000000;
					4'd9: HEX4 = 7'b0010000;
					default: HEX4 = 7'b1111111;
			  endcase

			  // HEX3 - y_tens
			  case (y_tens)
					4'd0: HEX3 = 7'b1000000;
					4'd1: HEX3 = 7'b1111001;
					4'd2: HEX3 = 7'b0100100;
					4'd3: HEX3 = 7'b0110000;
					4'd4: HEX3 = 7'b0011001;
					4'd5: HEX3 = 7'b0010010;
					4'd6: HEX3 = 7'b0000010;
					4'd7: HEX3 = 7'b1111000;
					4'd8: HEX3 = 7'b0000000;
					4'd9: HEX3 = 7'b0010000;
					default: HEX3 = 7'b1111111;
			  endcase

			  // HEX2 - y_ones
			  case (y_ones)
					4'd0: HEX2 = 7'b1000000;
					4'd1: HEX2 = 7'b1111001;
					4'd2: HEX2 = 7'b0100100;
					4'd3: HEX2 = 7'b0110000;
					4'd4: HEX2 = 7'b0011001;
					4'd5: HEX2 = 7'b0010010;
					4'd6: HEX2 = 7'b0000010;
					4'd7: HEX2 = 7'b1111000;
					4'd8: HEX2 = 7'b0000000;
					4'd9: HEX2 = 7'b0010000;
					default: HEX2 = 7'b1111111;
			  endcase

			  // HEX1 - dir MSB (0 or 1)
			  case (dir_msb_digit)
					4'd0: HEX1 = 7'b1000000;
					4'd1: HEX1 = 7'b1111001;
					default: HEX1 = 7'b1111111;
			  endcase

			  // HEX0 - dir LSB (0 or 1)
			  case (dir_lsb_digit)
					4'd0: HEX0 = 7'b1000000;
					4'd1: HEX0 = 7'b1111001;
					default: HEX0 = 7'b1111111;
			  endcase
		 end

	endmodule
