`timescale 1ns / 1ps

module testbench ( );

    // 50 MHz board clock → 20 ns period
    parameter CLOCK_PERIOD = 20;

    reg        CLOCK_50;
    reg  [0:0] KEY;          // KEY[0] = RESET_N (active-low)
    wire [7:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;

    // clock init
    initial begin
        CLOCK_50 <= 1'b0;
    end

    // same "always @(*)" style clock generator as your template
    always @(*) begin : Clock_Generator
        #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
    end

    // reset pulse (hold low, then release)
    initial begin
        KEY[0] <= 1'b0;     // assert RESET_N low
        #200;
        KEY[0] <= 1'b1;     // deassert reset
    end

    // ---------------- DUT ----------------
    // If your vga has RESET_N (recommended):
    vga U1 (
        .CLOCK_50 (CLOCK_50),
        .RESET_N  (KEY[0]),
        .VGA_R    (VGA_R),
        .VGA_G    (VGA_G),
        .VGA_B    (VGA_B),
        .VGA_HS   (VGA_HS),
        .VGA_VS   (VGA_VS)
    );

    // If your current vga has NO reset port yet, use this instead:
    // vga U1 (
    //     .CLOCK_50 (CLOCK_50),
    //     .VGA_R    (VGA_R),
    //     .VGA_G    (VGA_G),
    //     .VGA_B    (VGA_B),
    //     .VGA_HS   (VGA_HS),
    //     .VGA_VS   (VGA_VS)
    // );

endmodule
