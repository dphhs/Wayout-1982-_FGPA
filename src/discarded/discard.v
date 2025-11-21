/*
// Polygon Drawing
//========================================================

    assign draw_lines = SW[1];

    // Line Draw State Machine
    parameter
        INIT = 2'b00,
        DRAW = 2'b01,
        IDLE = 2'b10;

    // Internal Signal
    reg [2:0] line_id; 
    reg [1:0] state;
    reg line_start;
//======
    reg done;
//======
    reg [nX:0] mux_x0, mux_x1, mux_y0, mux_y1;
    always @(posedge CLOCK_50) begin
        case(state)
            INIT: begin
                state <= DRAW;
                line_start <= 1;
                if (line_id == 2'd0) begin  // (x0,y0) (x1,y1)
                    mux_x0 <= X0; mux_y0 <= Y0;
                    mux_x1 <= X1; mux_y1 <= Y1;
                end else if (line_id == 2'd1) begin  // (x1,y1) (x2,y2)
                    mux_x0 <= X1; mux_y0 <= Y1;
                    mux_x1 <= X2; mux_y1 <= Y2;
                end else if (line_id == 2'd2) begin  // (x2,y2) (x3,y3)
                    mux_x0 <= X2; mux_y0 <= Y2;
                    mux_x1 <= X3; mux_y1 <= Y3;
                end else begin  // (x3,y3) (x0,y0)
                    mux_x0 <= X3; mux_y0 <= Y3;
                    mux_x1 <= X0; mux_y1 <= Y0;
                end
            end
            DRAW: begin
                line_start <= 0;
                if(line_done) begin
                    if (line_id == 3) begin  // final line
                        state <= IDLE;
                    //===============
                        done <= 1'b1;
                    //===============
                    end else begin
                        state <= INIT;
                        line_id <= line_id + 1;
                    end
                end
            end
            default: begin  // IDLE
                //============
                    done <= 1'b0;
                //=============
                if (draw_lines) begin
                    state <= INIT;
                    line_id <= 2'b0;
                end
            end
        endcase
    end

    wire line_drawing, line_busy, line_done;
    // Draw Line Module
    draw_line #(.CORDW(nX+1))  
    u_draw_line (  // signed coordinate width
        .clk(CLOCK_50),           
        .rst(!Resetn),
        .start(line_start),
        .oe(Write),
        .x0(mux_x0),
        .x1(mux_x1),
        .y0(mux_y0),
        .y1(mux_y1),
        .x(draw_X),
        .y(draw_Y),
        .drawing(line_drawing),
        .busy(line_busy),
        .done(line_done)
    );

*/



//===========================================================



/*
Draw Lines
    draw_line_1d #(.CORDW(nX))  
    u_draw_line_1d (  
        .clk(CLOCK_50),           
        .rst(!Resetn),
        .start(Start),
        .oe(Write),
        .x0(X0),
        .x1(X1),
        .x(X),
        .drawing(Drawing),
        .busy(Busy),
        .done(Done)              
    );
*/

/*
draw_rectangle #(.CORDW(nX))
    u_draw_rectangle ( 
        .clk(CLOCK_50),           
        .rst(!Resetn),
        .start(Start),
        .oe(Write),
        .x0(X0),
        .x1(X1),
        .y0(Y0),
        .y1(Y1),
        .x(MUX_X),
        .y(MUX_Y),
        .drawing(Drawing),
        .busy(Busy),
        .done(Done)
    );
*/

/*
module draw_rectangle_fill #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start rectangle drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0, y0,  // vertex 0
    input  wire logic signed [CORDW-1:0] x1, y1,  // vertex 2
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );
*/



/*
// syncronizer, implemented as two FFs in series
module sync(D, Resetn, Clock, Q);
    input wire D;
    input wire Resetn, Clock;
    output reg Q;

    reg Qi; // internal node

    always @(posedge Clock)
        if (Resetn == 0) begin
            Qi <= 1'b0;
            Q <= 1'b0;
        end
        else begin
            Qi <= D;
            Q <= Qi;
        end
endmodule

// n-bit register with enable
module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input wire [n-1:0] R;
    input wire Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule

// n-bit up/down-counter with reset, load, enable, and direction control
module upDn_count #(
    parameter n = 8
) (R, Clock, Resetn, L, E, Dir, Q);
    input wire [n-1:0] R;
    input wire Clock, Resetn, E, L, Dir;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= {n{1'b0}};
        else if (L == 1)
            Q <= R;
        else if (E)
            if (Dir)
                Q <= Q + {{n-1{1'b0}},1'b1};
            else
                Q <= Q - {{n-1{1'b0}},1'b1};
endmodule

*/