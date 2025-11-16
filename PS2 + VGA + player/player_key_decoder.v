module player_key_decoder(clock, resetn, scancode, scancode_valid, forward, backward, rotateA, rotateD);

	//Input
	input clock, resetn;
	input [7:0] scancode;
	input scancode_valid;
	
	//Output
	output reg forward, backward, rotateA, rotateD;
	
	reg skip_flag; //handle break code (F0) (only when releases)
	
	always @ (posedge clock) begin
		if(!resetn) begin
			skip_flag <= 1'b0;
			forward <= 1'b0;
			backward <= 1'b0;
			rotateA <= 1'b0;
			rotateD <+ 1'b0;
		end
		else begin
			forward <= 1'b0;
			backward <= 1'b0;
			rotateA <= 1'b0;
			rotateD <= 1'b0;
			
			if(scancode_valid) begin
				if(skip_flag == 1'b1) begin	//Skip this input (the input is a release)
					skip_flag <= 1'b0;			//Reset the flag
				end
				
				else if(scancode == 8'hF0) begin //Put up flag when input is 8'hF0 (release)
					skip_flag <= 1'bd1;
				end
				
				else begin
					//MAKE code → trigger movement
                 case (scancode)
                   8'h1D: forward <= 1'b1;   // W key
						 8'h1B: backward <= 1'b1;  // S key
						 8'h1C: rotateA <= 1'b1;	//A key (to turn left)
                   8'h23: rotateD  <= 1'b1;   //D key (to turn right)
                   default: ;              // no movement
                 endcase
                end
            end
        end
    end
endmodule
				
				
				
				
				