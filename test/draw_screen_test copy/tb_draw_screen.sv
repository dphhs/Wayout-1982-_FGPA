`timescale 1ns/1ps

module tb_draw_screen;

    // Parameters
    parameter CORDW = 11;

    // Signals
    logic clk;
    logic rstn;
    logic refresh;
    logic signed [CORDW-1:0] draw_X, draw_Y;
    logic busy;
    logic done;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz clock

    // Instantiate the DUT
    draw_screen #(.CORDW(CORDW)) dut (
        .clk(clk),
        .rstn(rstn),
        .refresh(refresh),
        .draw_X(draw_X),
        .draw_Y(draw_Y),
        .busy(busy),
        .done(done)
    );

    // Test sequence
    initial begin
        // Initialize
        rstn = 0;
        refresh = 0;
        #20;
        rstn = 1;

        // Wait a few cycles
        #20;

        // Start a refresh
        $display("Applying refresh at time %0t", $time);
        refresh = 1;
        #10;
        refresh = 0;

        // Wait for drawing to complete
        wait(done);
        $display("Drawing done at time %0t", $time);

        // Wait a few more cycles
        #50;

        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | draw_X=%0d draw_Y=%0d busy=%b done=%b",
                  $time, draw_X, draw_Y, busy, done);
    end

endmodule
