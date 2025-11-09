// Copyright (c) 2020 FPGAcademy
// Please see license at https://github.com/fpgacademy/DESim

`timescale 1ns / 1ns
`default_nettype none

module tb();
    reg CLOCK_50 = 0;               // DE-series 50 MHz clock
    reg [9:0] SW = 0;               // DE-series SW switches
    reg [3:0] KEY = 0;              // DE-series pushbutton keys
    wire [(8*6)-1:0] HEX;           // HEX displays (six ports)
    wire [9:0] LEDR;                // DE-series LEDs

    reg key_action = 0;             // used only if emulating PS/2
    reg [7:0] scan_code = 0;
    wire [2:0] ps2_lock_control;

    wire [9:0] VGA_X;               // "VGA" column
    wire [8:0] VGA_Y;               // "VGA" row
    wire [23:0] VGA_COLOR;          // "VGA pixel" colour
    wire plot;                      // pulse to draw pixel
    wire [31:0] GPIO;               // DE-series GPIO port

    // >>> Reset handling: hold KEY0 low, then release <<<
    initial begin
        KEY = 4'b0000;          // KEY0=0 => reset asserted
        #200 KEY[0] = 1'b1;     // release reset after 200 ns
        // (optional) tweak switches:
        // SW = 10'h000;
    end

    initial $sim_fpga(CLOCK_50, SW, KEY, LEDR, HEX, key_action, scan_code,
                      ps2_lock_control, VGA_X, VGA_Y, VGA_COLOR, plot, GPIO);

    // DE-series HEX0..HEX5 ports
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // 50 MHz clock
    always #10 CLOCK_50 <= ~CLOCK_50;

    // Pack HEX (6×8 bits expected by DESim)
    assign HEX[47:40] = {1'b0, HEX0};
    assign HEX[39:32] = {1'b0, HEX1};
    assign HEX[31:24] = {1'b0, HEX2};
    assign HEX[23:16] = {1'b0, HEX3};
    assign HEX[15: 8] = {1'b0, HEX4};
    assign HEX[ 7: 0] = {1'b0, HEX5};

    top DUT (
        .CLOCK_50(CLOCK_50), .SW(SW), .KEY(KEY),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .LEDR(LEDR),
        .VGA_X(VGA_X), .VGA_Y(VGA_Y), .VGA_COLOR(VGA_COLOR), .plot(plot)
    );
endmodule
