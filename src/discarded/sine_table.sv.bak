`timescale 1ns / 1ps
`default_nettype none

module sine_lut_360 #(
    parameter ROM_DEPTH = 64,
    parameter ROM_WIDTH = 8,
    parameter ROM_FILE="sine_table_64x8.mem",  // file to populate ROM
    parameter ADDRW     = $clog2(4*ROM_DEPTH) // 0°–360° full circle
) (
    input  wire [ADDRW-1:0] angle_id,        // 0..255 for full circle
    output wire signed [2*ROM_WIDTH-1:0] sine // Q8.8 output
);

    // Internal signals
    wire [$clog2(ROM_DEPTH)-1:0] tab_id;
    wire [ROM_WIDTH-1:0] tab_data;
    
    wire [1:0] quad;
    assign quad = angle_id[ADDRW-1:ADDRW-2]; // top 2 bits = quadrant

    // Compute the ROM index for 0°–90°
    assign tab_id = (quad == 2'b00) ? angle_id[ADDRW-3:0] : 
                    (quad == 2'b01) ? (2*ROM_DEPTH - angle_id[ADDRW-3:0]) :
                    (quad == 2'b10) ? (angle_id[ADDRW-3:0] - 2*ROM_DEPTH) :
                                      (4*ROM_DEPTH - angle_id[ADDRW-3:0]);

    // ROM instantiation (async read)
    rom_async #(
        .WIDTH(ROM_WIDTH),
        .DEPTH(ROM_DEPTH),
        .INIT_F(ROM_FILE)
    ) sine_rom (
        .addr(tab_id),
        .data(tab_data)
    );

    // Map ROM output to full-circle signed Q8.8
    assign sine = (angle_id == ROM_DEPTH)       ? {{ROM_WIDTH-1{1'b0}}, 1'b1, {ROM_WIDTH{1'b0}}} :   // sin(90°)=+1.0
                  (angle_id == 3*ROM_DEPTH)     ? {{ROM_WIDTH{1'b1}}, {ROM_WIDTH{1'b0}}} :         // sin(270°)=-1.0
                  (quad[1] == 1'b0)             ? {{ROM_WIDTH{1'b0}}, tab_data} :                  // Quadrant I & II = +
                                                  {2*ROM_WIDTH{1'b0}} - {{ROM_WIDTH{1'b0}}, tab_data}; // Quadrant III & IV = -

endmodule



// Project F Library - Sine Table
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

module sine_table #(
    parameter ROM_DEPTH=64,  // number of entries in sine ROM for 0° to 90°
    parameter ROM_WIDTH=8,   // width of sine ROM data in bits
    parameter ROM_FILE="",   // sine table file to populate ROM
    parameter ADDRW=$clog2(4*ROM_DEPTH)  // full circle is 0° to 360°
    ) (
    input  wire logic [ADDRW-1:0] id,  // table ID to lookup
    output      logic signed [2*ROM_WIDTH-1:0] data  // answer (fixed-point)
    );

    // sine table ROM: 0°-90°
    logic [$clog2(ROM_DEPTH)-1:0] tab_id;
    logic [ROM_WIDTH-1:0] tab_data;
    rom_async #(
        .WIDTH(ROM_WIDTH),
        .DEPTH(ROM_DEPTH),
        .INIT_F(ROM_FILE)
    ) sine_rom (
        .addr(tab_id),
        .data(tab_data)
    );

    logic [1:0] quad;  // quadrant we're in: I, II, III, IV
    always_comb begin
        quad = id[ADDRW-1:ADDRW-2];
        case (quad)
            /* verilator lint_off WIDTH */
            2'b00: tab_id = id[ADDRW-3:0];                //  I:    0° to  90°
            2'b01: tab_id = 2*ROM_DEPTH - id[ADDRW-3:0];  // II:   90° to 180°
            2'b10: tab_id = id[ADDRW-3:0] - 2*ROM_DEPTH;  // III: 180° to 270°
            2'b11: tab_id = 4*ROM_DEPTH - id[ADDRW-3:0];  // IV:  270° to 360°
            /* verilator lint_on WIDTH */
        endcase
    end

    always_comb begin
        if (id == ROM_DEPTH) begin  // sin(90°) = +1.0
            data = {{ROM_WIDTH-1{1'b0}}, 1'b1, {ROM_WIDTH{1'b0}}};
        end else if (id == 3*ROM_DEPTH) begin  // sin(270°) = -1.0
            data = {{ROM_WIDTH{1'b1}}, {ROM_WIDTH{1'b0}}};
        end else begin
            if (quad[1] == 0) begin  // positive in quadrant I and II
                data = {{ROM_WIDTH{1'b0}}, tab_data};
            end else begin
                data = {2*ROM_WIDTH{1'b0}} - {{ROM_WIDTH{1'b0}}, tab_data};
            end
        end
    end
endmodule