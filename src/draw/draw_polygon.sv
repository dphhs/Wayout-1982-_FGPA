module draw_polygon #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start rectangle drawing
    input  wire logic oe,              // output enable
    input  wire logic signed [CORDW-1:0] x0, y0,  // vertex 0
    input  wire logic signed [CORDW-1:0] x1, y1,  // vertex 1
    input  wire logic signed [CORDW-1:0] x2, y2,  // vertex 0
    input  wire logic signed [CORDW-1:0] x3, y3,  // vertex 1
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // Internal Signal
    reg [2:0] line_id; 
    reg line_start;
    reg line_done;

    // Current Line Coordinates
    reg [CORDW-1:0] mux_x0, mux_x1, mux_y0, mux_y1;

    // Line Draw State Machine
    parameter
        INIT = 2'b00,
        DRAW = 2'b01,
        IDLE = 2'b10;

    reg [1:0] state;
    always @(posedge clk) begin
        case(state)
            INIT: begin
                state <= DRAW;
                line_start <= 1;
                if (line_id == 2'd0) begin  // (x0,y0) (x1,y1)
                    mux_x0 <= x0; mux_y0 <= y0;
                    mux_x1 <= x1; mux_y1 <= y1;
                end else if (line_id == 2'd1) begin  // (x1,y1) (x2,y2)
                    mux_x0 <= x1; mux_y0 <= y1;
                    mux_x1 <= x2; mux_y1 <= y2;
                end else if (line_id == 2'd2) begin  // (x2,y2) (x3,y3)
                    mux_x0 <= x2; mux_y0 <= y2;
                    mux_x1 <= x3; mux_y1 <= y3;
                end else begin  // (x3,y3) (x0,y0)
                    mux_x0 <= x3; mux_y0 <= y3;
                    mux_x1 <= x0; mux_y1 <= y0;
                end
            end
            DRAW: begin
                line_start <= 0;
                if(line_done) begin
                    if (line_id == 3) begin  // final line
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        state <= INIT;
                        line_id <= line_id + 1;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= INIT;
                    line_id <= 2'b0;
                    busy <= 1;
                end
            end
        endcase
        if (rst) begin
            state <= IDLE;
            line_id <= 0;
            line_start <= 0;
            busy <= 0;
            done <= 0;
        end
    end

    wire line_drawing, line_busy;
    // Draw Line Module
    draw_line #(.CORDW(CORDW))  
    u_draw_line (  // signed coordinate width
        .clk(clk),           
        .rst(!rst),
        .start(line_start),
        .oe(oe),
        .x0(mux_x0),
        .x1(mux_x1),
        .y0(mux_y0),
        .y1(mux_y1),
        .x(x),
        .y(y),
        .drawing(),
        .busy(),
        .done(line_done)
    );
endmodule