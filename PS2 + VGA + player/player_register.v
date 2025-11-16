`include "params.vh"

module player_register (
    input  wire        clk,
    input  wire        resetn,

    // next-state from player_update
    input  wire [15:0] next_x,
    input  wire [15:0] next_y,
    input  wire [7:0]  next_angle,   // 8-bit angle from player_update

    // registered outputs (current state)
    output reg  [15:0] x_position,
    output reg  [15:0] y_position,
    output reg  [8:0]  angle         // top-level uses 9 bits
);

    always @(posedge clk) begin
        if (!resetn) begin
            // choose a spawn location later if you want
            x_position <= 16'd0;
            y_position <= 16'd0;
            angle      <= 9'd0;
        end else begin
            x_position <= next_x;
            y_position <= next_y;
            // store next_angle, widen to 9 bits (MSB 0 for now)
            angle      <= {1'b0, next_angle};
        end
    end

endmodule
