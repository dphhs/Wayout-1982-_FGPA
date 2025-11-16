module player_update (
	 input  clock,
    input  resetn,
    input  forward,
    input  backward,
    input  rotateA,
	 input  rotateD,

    input  [15:0] current_x,
    input  [15:0] current_y,
    input  [8:0]  current_angle,

    output reg  [15:0] new_x,
    output reg  [15:0] new_y,
    output reg  [8:0]  new_angle				//CONFIRM LATER HOW MANY BITS
);
	
	//localparam W = 8'h1D, S = 8'h1B, D = 8'h23;
	localparam signed [15:0] MOVE_SPEED = 16'sd64;
	
	//Make cardinal directions parameter
	localparam [8:0] EAST  = 9'd0;
   localparam [8:0] NORTH = 9'd90;
   localparam [8:0] WEST  = 9'd180;
   localparam [8:0] SOUTH = 9'd270;
	
	localparam [7:0] ROTATION_STEP = 8'd64;
	
	reg signed [9:0] angle_temp;
	reg [8:0] angle_wrapped;
	
	always @ (*) begin
		if(angle_temp < 0)
			angle_wrapped = angle_temp + 360;
		else if(angle_temp >= 360)
			angle_wrapped = angle_temp - 360;
		else
			angle_wrapped = angle_temp[8:0];
	end
	
	always @ (posedge clock or negedge resetn) begin
		if(!resetn) begin
			new_x <= 16'd0;
			new_y <= 16'd0;
			new_angle <= EAST;
			ang_temp <= EAST;
		end
		else begin
			//Default to hold state
			new_x <= current_x;
			new_y <= current_y;
			new_angle <= current_angle;
			angle_temp <= current_angle;
			
			if(rotateA && !rotateD) begin
				angle_temp <= current_angle + ROTATION_STEP;
			end
			else if (rotateD && !rotateA) begin
				angle_temp <= current_angle - ROTATION_STEP;
			end
			
			new_angle <= angleW_wrapped;
			
			case (current_angle)
				EAST: begin
					if (forward) new_x <= $signed(current_x) + MOVE_SPEED;
					if (backward) new_x <= $signed(current_x) - MOVE_SPEED;
			end
			
			NORTH: begin
					if (forward)  new_y <= $signed(current_y) - MOVE_SPEED;
					if (backward) new_y <= $signed(current_y) + MOVE_SPEED;
			end
			
			WEST: begin
					if (forward)  new_x <= $signed(current_x) - MOVE_SPEED;
               if (backward) new_x <= $signed(current_x) + MOVE_SPEED;
         end
			
			SOUTH: begin
					if (forward)  new_y <= $signed(current_y) + MOVE_SPEED;
               if (backward) new_y <= $signed(current_y) - MOVE_SPEED;
			end
		endcase
		end
	end
endmodule
			
		 
	//Calculate dx dy
	reg signed [15:0] dx;
   reg signed [15:0] dy;
	

	
	
	
	
	
	
		
endmodule
			
