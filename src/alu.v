module ALU (
    input [15:0] a, 
    input [15:0] b, 
    input [2:0] alu_control, 
    output reg [15:0] out
);

    wire [15:0] ab_full = a * b;
    wire [7:0] ab_scaled = ab_full[11:4]; // (8 + 4 - 1 : 4)
    always @(*)
	begin
	case (alu_control)
            3'b000: out = a + b;            // add
            3'b001: out = a - b;            // sub
            3'b010: out = (a * b)[11:4];    // Multi

            default: out = 16'b0;
	endcase
	end
endmodule