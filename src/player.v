`include "params.vh"

module player_register(
    input forward,
    input rotate,
    input resetn, 
    input clk,
    output reg [15:0] x_position,
    output reg [15:0] y_position,
    output reg [8:0] angle
);

// Parameter
    parameter
        rotateSpeed = 9'd1,
        forwardSpeed = 16'd5;

// Player Register
always@(posedge clk)  
begin: Player_Register
    if(!resetn) begin
        x_position <= 16'd0;
        y_position <= 16'd0;
        angle <= 9'd0;
    end else begin
        // Increment
        if(rotate) begin
            if(angle == 9'd359)
                angle <= 9'd0;
            else
                angle <= angle + rotateSpeed;
        end     
          
        if(forward) begin
            x_position <= x_position + $rtoi(forwardSpeed * $cos(angle * 2*3.141592/360));
            y_position <= y_position + $rtoi(forwardSpeed * $sin(angle * 2*3.141592/360));
        end
    end
end
endmodule