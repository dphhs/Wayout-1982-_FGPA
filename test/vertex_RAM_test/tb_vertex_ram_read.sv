`timescale 1ns/1ps

module tb_vertex_ram_read();

    reg clk = 0;
    reg [5:0] rdaddr;
    wire [9:0] q;

    // Instantiate your RAM
    vertex_ram uut (
        .clock(clk),
        .data(10'b0),      // not writing
        .wraddress(6'b0),  // not writing
        .rdaddress(rdaddr),
        .wren(1'b0),       // disable write
        .q(q)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        rdaddr = 0;
        #10;

        // Read all 64 preloaded addresses
        for (integer i = 0; i < 64; i = i + 1) begin
            rdaddr = i;
            #10; // wait for output to settle
            $display("Address %0d: Data = %0d", i, q);
        end

        $display("Preload test finished.");
        $stop;
    end

endmodule
