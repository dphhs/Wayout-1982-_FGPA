`timescale 1ns / 1ps
`default_nettype none

module tb_sine_lut_360;

    // Parameters matching DUT
    localparam ROM_DEPTH = 64;
    localparam ROM_WIDTH = 8;
    localparam ADDRW     = $clog2(4*ROM_DEPTH);

    // DUT signals
    reg  [ADDRW-1:0] angle_id;
    wire signed [2*ROM_WIDTH-1:0] sine_out;

    // Instantiate DUT
    sine_lut_360 #(
        .ROM_DEPTH(ROM_DEPTH),
        .ROM_WIDTH(ROM_WIDTH),
        .ROM_FILE("sine_table_64x8.mem")
    ) dut (
        .angle_id(angle_id),
        .sine(sine_out)
    );
    
    // Simulation variables
    integer i;
    real    sine_float;

    initial begin
        $display("=== Sine LUT 360° Test ===");
        $display(" angle_id | sine_out (Q8.8) | sine (float)");
        $display("------------------------------------------");

        for (i = 0; i < 4*ROM_DEPTH; i = i + 1) begin
            angle_id = i;
            #10; // allow time to settle

            // Convert Q8.8 fixed-point to float
            sine_float = $itor(sine_out) / 256.0;

            $display("   %3d     | %6d (0x%04h) | %f",
                     angle_id, sine_out, sine_out, sine_float);
        end

        $display("=== Test Complete ===");
        $stop;
    end

endmodule

`default_nettype wire
