`timescale 1ns/1ps
module testbench;

  reg        CLOCK_50 = 1'b0;
  reg  [3:0] KEY      = 4'b1111;   // KEY[0]=1 -> resetn=0 (in reset)

  wire [7:0] VGA_R, VGA_G, VGA_B;
  wire       VGA_HS, VGA_VS;
  wire       VGA_BLANK_N, VGA_SYNC_N, VGA_CLK;

  // 50 MHz board clock (20 ns period)
  always #10 CLOCK_50 = ~CLOCK_50;

  // Reset pulse: hold in reset 200 ns, then release
  initial begin
    KEY[0] = 1'b1;   // reset asserted (resetn=~1=0)
    #200;
    KEY[0] = 1'b0;   // deassert (resetn=1)
  end

  // Instantiate DUT (instance name U1 so wave.do paths like /testbench/U1/... work)
  vga u1 (
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B),
    .VGA_HS(VGA_HS), .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK)
  );

endmodule
