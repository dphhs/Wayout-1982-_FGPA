module player_control_top (
    input  wire       CLOCK_50,
    input  wire [0:0] KEY,
    inout  wire       PS2_CLK,
    inout  wire       PS2_DAT,
    output wire [9:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,
    output wire [15:0] x_position,
    output wire [15:0] y_position,
    output wire [8:0]  angle
);
    wire resetn = KEY[0];

    //from PS/2 controller
    wire [7:0] scancode;
    wire       scancode_valid;

    //decoded movement signals
    wire forward;
	 wire backward;
    wire rotate;
	 
	 
	 //wires to connect player_update and player_register
	 wire [15:0] new_x, new_y;
	 wire [7:0] new_angle;
	 
	 

    // 1) PS/2 scancode receiver
    ps2controller user_input (.CLOCK_50(CLOCK_50), .KEY(KEY), .PS2_CLK(PS2_CLK), .PS2_DAT(PS2_DAT), .LEDR(LEDR), .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .scancode_out(scancode),
        .scancode_valid(scancode_valid)
    );

    // 2) Decode scancodes into forward/rotate pulses
    player_key_decoder decode_user_input (.clock(CLOCK_50), .resetn(resetn), .scancode(scancode), .scancode_valid(scancode_valid), .forward(forward), 
	 .backward(backward), .rotate(rotate)
    );
	 
	 // 3) player_update
	 player_update update_position (
    .clock(CLOCK_50),
    .resetn(resetn),
    .forward(forward),
    .backward(1'b0),
    .rotate(rotate),
    .current_x(x_position),
    .current_y(y_position),
    .current_angle(angle[7:0]),
    .new_x(new_x),
    .new_y(new_y),
    .new_angle(new_angle)
);
	 
	 

	 // 4) Player register (position + angle)
	 player_register player (
		 .clk        (CLOCK_50),
		 .resetn     (resetn),
		 .next_x     (new_x),
		 .next_y     (new_y),
		 .next_angle (new_angle),
		 .x_position (x_position),
		 .y_position (y_position),
		 .angle      (angle)
	);



endmodule
