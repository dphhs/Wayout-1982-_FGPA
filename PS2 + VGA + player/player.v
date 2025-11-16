`default_nettype none

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
    output reg  [1:0]  dir           // 2-bit direction (00=E,01=N,10=W,11=S)
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

    //===========================================================
    // Direction encoding: 2 bits
    //===========================================================
    localparam [1:0] DIR_EAST  = 2'b00;
    localparam [1:0] DIR_NORTH = 2'b01;
    localparam [1:0] DIR_WEST  = 2'b10;
    localparam [1:0] DIR_SOUTH = 2'b11;

    //===========================================================
    // Key state: last key, timer, break flag, pulses
    //===========================================================
    reg        break_flag;         // 1 after F0, cleared by next scancode
    reg [7:0]  last_key;           // last accepted MAKE code

    // small timer to gate repeats
    reg [23:0] repeat_counter;
    localparam [23:0] REPEAT_DELAY = 24'd6_000_000; // ~0.12 s @ 50 MHz

    reg forward_pulse;             // one-tile move forward (W)
    reg backward_pulse;            // one-tile move backward (S)
    reg rotateA;                   // rotate left (A)
    reg rotateD;                   // rotate right (D)

    //===========================================================
    // KEY DECODER with F0 handling + last-key + timer filter
    //===========================================================
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            break_flag      <= 1'b0;
            last_key        <= 8'h00;
            repeat_counter  <= 24'd0;
            forward_pulse   <= 1'b0;
            backward_pulse  <= 1'b0;
            rotateA         <= 1'b0;
            rotateD         <= 1'b0;
        end
        else begin
            // default: pulses clear each cycle
            forward_pulse  <= 1'b0;
            backward_pulse <= 1'b0;
            rotateA        <= 1'b0;
            rotateD        <= 1'b0;

            // timer free-runs up to REPEAT_DELAY
            if (repeat_counter < REPEAT_DELAY)
                repeat_counter <= repeat_counter + 24'd1;

            if (scancode_valid) begin
                //-----------------------------------------------
                // 1) F0 → mark that next byte is a BREAK
                //-----------------------------------------------
                if (scancode == 8'hF0) begin
                    break_flag <= 1'b1;
                end

                //-----------------------------------------------
                // 2) BREAK code: key release, clear last_key
                //-----------------------------------------------
                else if (break_flag) begin
                    break_flag <= 1'b0;

                    // if this release matches last_key, clear it
                    if (scancode == last_key)
                        last_key <= 8'h00;
                    // no pulses on release
                end

                //-----------------------------------------------
                // 3) MAKE code, break_flag == 0
                //-----------------------------------------------
                else begin
                    // Accept this key if it differs from last_key
                    // OR the timer says it's been held long enough
                    if ((scancode != last_key) ||
                        (repeat_counter >= REPEAT_DELAY)) begin

                        // this key is now the "last" one
                        last_key       <= scancode;
                        repeat_counter <= 24'd0; // restart delay

                        // generate movement/rotation pulses
                        case (scancode)
                            8'h1D: begin
                                // W
                                forward_pulse <= 1'b1;
                            end
                            8'h1B: begin
                                // S
                                backward_pulse <= 1'b1;
                            end
                            8'h1C: begin
                                // A
                                rotateA <= 1'b1;
                            end
                            8'h23: begin
                                // D
                                rotateD <= 1'b1;
                            end
                            default: begin
                                // other keys: nothing
                            end
                        endcase
                    end
                    // else: duplicate key too soon -> ignore
                end
            end
        end
    end

    //===========================================================
    // PLAYER REGISTER + UPDATE FSM
    //===========================================================
    reg [4:0] next_x, next_y;
    reg [1:0] next_dir;

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x_position <= 5'd1;        // starting tile
            y_position <= 5'd1;
            dir        <= DIR_EAST;    // facing east
        end
        else begin
            x_position <= next_x;
            y_position <= next_y;
            dir        <= next_dir;
        end
    end

    //===========================================================
    // FSM UPDATE LOGIC (grid movement on 20x20 map)
    //===========================================================
    always @* begin
        next_x   = x_position;
        next_y   = y_position;
        next_dir = dir;

        // ROTATION
        if (rotateA && !rotateD)
            next_dir = dir + 2'b01; // left turn (E->N->W->S->E)
        else if (rotateD && !rotateA)
            next_dir = dir - 2'b01; // right turn (E->S->W->N->E)

        // MOVEMENT (1 tile per accepted W/S) with bounds [0..19]
        case (dir)
            DIR_EAST: begin
                if (forward_pulse  && x_position < 5'd19) next_x = x_position + 5'd1;
                if (backward_pulse && x_position > 5'd0)  next_x = x_position - 5'd1;
            end

            DIR_NORTH: begin
                if (forward_pulse  && y_position > 5'd0)  next_y = y_position - 5'd1;
                if (backward_pulse && y_position < 5'd19) next_y = y_position + 5'd1;
            end

            DIR_WEST: begin
                if (forward_pulse  && x_position > 5'd0)  next_x = x_position - 5'd1;
                if (backward_pulse && x_position < 5'd19) next_x = x_position + 5'd1;
            end

            DIR_SOUTH: begin
                if (forward_pulse  && y_position < 5'd19) next_y = y_position + 5'd1;
                if (backward_pulse && y_position > 5'd0)  next_y = y_position - 5'd1;
            end
        endcase
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
