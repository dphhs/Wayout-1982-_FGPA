`timescale 1ns/1ps

// ----------------------------------------------------
// Mock RAM (replaces actual vertex_ram in DUT)
// ----------------------------------------------------
module vertex_ram(
    input  logic        clock,
    input  logic [9:0]  data,
    input  logic [5:0]  rdaddress,
    input  logic [5:0]  wraddress,
    input  logic        wren,
    output logic [9:0]  q
);

    logic [9:0] mem [0:63];

    // preload only shape 0 for simplicity
    initial begin
        mem[0] = 10'd10;  // x0
        mem[1] = 10'd20;  // y0
        mem[2] = 10'd30;  // x1
        mem[3] = 10'd40;  // y1
        mem[4] = 10'd50;  // x2
        mem[5] = 10'd60;  // y2
        mem[6] = 10'd80;  // x3
        mem[7] = 10'd333;  // y3
    end

    always @(posedge clock) begin
        if (wren)
            mem[wraddress] <= data;

        q <= mem[rdaddress];
    end

endmodule

// ----------------------------------------------------
// Testbench
// ----------------------------------------------------
module vertex_loader_tb;

    logic clk;
    logic rst_n;
    logic start_loading;
    logic line_done;
    logic [2:0] shape_sel;

    logic [9:0] x0, y0, x1, y1, x2, y2, x3, y3;
    logic draw_lines, busy, ready;

    // DUT
    vertex_loader dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_loading(start_loading),
        .line_done(line_done),
        .shape_sel(shape_sel),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .x3(x3), .y3(y3),
        .draw_lines(draw_lines)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        start_loading = 0;
        line_done = 0;
        shape_sel = 0;

        repeat(4) @(posedge clk);
        rst_n = 1;

        @(posedge clk);
        start_loading = 1;

        @(posedge clk);
        start_loading = 0;

        wait(ready == 1);

        $display("Loaded vertices:");
        $display("x0=%d y0=%d", x0, y0);
        $display("x1=%d y1=%d", x1, y1);
        $display("x2=%d y2=%d", x2, y2);
        $display("x3=%d y3=%d", x3, y3);

        @(posedge clk);
        line_done = 1;

        @(posedge clk);
        line_done = 0;

        repeat(5) @(posedge clk);
        $finish;
    end

endmodule
