module top (
    CLOCK_50, SW, KEY,
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    LEDR,
    VGA_X, VGA_Y, VGA_COLOR, plot
);
    input  CLOCK_50;
    input  [9:0] SW;
    input  [3:0] KEY;
    output [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
    output [9:0] LEDR;

    // DESim pixel interface (DUT ports)
    input  [9:0]  VGA_X;
    input  [8:0]  VGA_Y;
    output reg [23:0] VGA_COLOR;
    output reg        plot;

    assign LEDR = SW;
    assign HEX0 = 7'h7F; assign HEX1 = 7'h7F; assign HEX2 = 7'h7F;
    assign HEX3 = 7'h7F; assign HEX4 = 7'h7F; assign HEX5 = 7'h7F;

    // Your VGA core
    wire [7:0] R,G,B;
    wire HS, VS;
    vga U1 (
        .CLOCK_50 (CLOCK_50),
        .KEY      (KEY),
        .VGA_R    (R), .VGA_G(G), .VGA_B(B),
        .VGA_HS   (HS), .VGA_VS(VS)
    );

    // ================================
    // DESim painter: pulse 'plot' when (VGA_X,VGA_Y) changes
    // ================================
    reg [9:0] x_d;
    reg [8:0] y_d;

    always @(posedge CLOCK_50) begin
        // default: no draw
        plot <= 1'b0;

        // detect coordinate advance from DESim
        if (VGA_X != x_d || VGA_Y != y_d) begin
            // pulse plot for exactly one cycle at the new coord
            plot      <= 1'b1;

            // --- SANITY: solid green ---
            VGA_COLOR <= 24'h00FF00;

            // --- After sanity passes, use your core output: ---
            // if (VGA_X < 640 && VGA_Y < 480)
            //     VGA_COLOR <= {R,G,B};
            // else
            //     VGA_COLOR <= 24'h000000;
        end

        // update previous coords
        x_d <= VGA_X;
        y_d <= VGA_Y;
    end
endmodule
