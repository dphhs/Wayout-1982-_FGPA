`timescale 1ns / 1ps

module tb_player_register_real();

    parameter CLOCK_PERIOD = 10;

    // Inputs
    reg forward;
    reg rotate;
    reg resetn;
    reg clk;

    // Outputs from DUT
    wire [15:0] x_position;
    wire [15:0] y_position;
    wire [8:0] angle;

    // Real-valued signals for waveform/display
    real x_real;
    real y_real;

    // Accumulated real positions for smooth display
    real x_real_acc = 0.0;
    real y_real_acc = 0.0;

    // Instantiate DUT
    player_register UUT (
        .forward(forward),
        .rotate(rotate),
        .resetn(resetn),
        .clk(clk),
        .x_position(x_position),
        .y_position(y_position),
        .angle(angle)
    );

    // Clock generation
    initial clk = 0;
    always #(CLOCK_PERIOD/2) clk = ~clk;

    // Stimulus: reset → rotate → forward
    initial begin
        // Apply reset for 2 clock cycles
        resetn = 0; forward = 0; rotate = 0;
        @(posedge clk);
        @(posedge clk);
        resetn = 1;

        // Step 1: rotate 30° (30 clocks)
        rotate = 1; forward = 0;
        repeat (30) @(posedge clk);
        rotate = 0;

        // Step 2: move forward (100 clocks)
        forward = 1;
        repeat (100) @(posedge clk);
        forward = 0;

        @(posedge clk);
        $stop;
    end

    // Update real-valued positions for waveform
    always @(posedge clk) begin
        if(forward) begin
            x_real_acc = x_real_acc + 5.0 * $cos(angle * 2*3.141592/360);
            y_real_acc = y_real_acc + 5.0 * $sin(angle * 2*3.141592/360);
        end
        x_real = x_real_acc;
        y_real = y_real_acc;
    end

    // Monitor real values
    initial begin
        $monitor("Time=%0t | resetn=%b | rotate=%b | forward=%b | x_real=%f | y_real=%f | angle=%0d",
                 $time, resetn, rotate, forward, x_real, y_real, angle);
    end

endmodule
