module player_register(
    input forward,
    input rotate,
    input resetn, 
    input clk,
    output reg [15:0] x_position,
    output reg [15:0] y_position,
    output reg [8:0] angle
);

parameter rotateSpeed = 9'd1;
parameter forwardSpeed = 16'd5;

// Internal real positions
real x_pos_real, y_pos_real;

always @(posedge clk) begin
    if(!resetn) begin
        x_pos_real <= 0.0;
        y_pos_real <= 0.0;
        angle <= 0;
        x_position <= 0;
        y_position <= 0;
    end else begin
        // Rotate with wrapping
        if (rotate)
            angle <= (angle + rotateSpeed) % 360;

        // Move forward smoothly
        if (forward) begin
            x_pos_real <= x_pos_real + forwardSpeed * $cos(angle * 2*3.141592/360);
            y_pos_real <= y_pos_real + forwardSpeed * $sin(angle * 2*3.141592/360);
        end

        // Output integer values for display
        x_position <= $rtoi(x_pos_real);
        y_position <= $rtoi(y_pos_real);
    end
end

endmodule
