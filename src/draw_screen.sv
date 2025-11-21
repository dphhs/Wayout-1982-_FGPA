// ==========================
    // Drawing module

    
// ============================
module draw_screen #(parameter CORDW=16) (  // signed coordinate width
    input       wire logic clk,             // clock
    input       wire logic rstn,             // reset
    input       wire logic refresh,           // start rectangle drawing

    /*
    input wire logic map;
    input wire logic px;
    input wire logic py;
    input wire logic direction;
    */

    /*
    output  wire logic signed [CORDW-1:0] x0, y0,  // vertex 0
    output  wire logic signed [CORDW-1:0] x1, y1,  // vertex 1
    output  wire logic signed [CORDW-1:0] x2, y2,  // vertex 0
    output  wire logic signed [CORDW-1:0] x3, y3,  // vertex 1
    */

    output      logic signed [CORDW-1:0] draw_X,  draw_Y,   // drawing 

    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
);

    // Setting Para
    parameter
        H       =   13'd400,
        W       =   13'd400,

        x_width =   5,
        y_width =   5,

        displace =  13'd20,
        east    =   2'b00,
        north   =   2'b01,
        west    =   2'b10,
        south   =   2'b11,

        D0      =   13'd20,
        D1      =   13'd70,
        D2      =   13'd100,
        D3      =   13'd120,
        D4      =   13'd110,
        D5      =   13'd105,
        D6      =   13'd100;

    // Player Para
    parameter
        row0    =   3'b011,
        row1    =   3'b001,
        row2    =   3'b110,  
        row3    =   3'b101,  
        row4    =   3'b001, 

        init_px =   3'd1,
        init_py =   3'd4,
        direction = 2'b01;

    // Parameter array: 1 row, 7 columns
    parameter logic [9:0] D [0:6] = '{
        13'd20,     // D0
        13'd70,     // D1
        13'd100,    // D2
        13'd120,    // D3
        13'd110,    // D4
        13'd105,    // D5
        13'd100     // D6
        };
        
    // draw_quad wires
    logic quad_start;
    logic quad_drawing, quad_busy, quad_done;
    logic Write = 1'b1;

    // 3 x 5 2D array (x=3, y=5)
    logic [2:0] map [0:4]; // 5 rows, 3 bits each row
    // map[py][px]
    logic [x_width + 1:0]px;
    logic [y_width + 1:0]py;
    // Initial Map
    always_ff @(posedge clk) begin
        if (!rstn) begin
            px <= init_px;
            py <= init_py;
            map[0] <= row0;
            map[1] <= row1;
            map[2] <= row2;
            map[3] <= row3;
            map[4] <= row4;
        end
    end

    // Usage
    logic [9:0] V;
    logic [y_width+1:0] index_x, index_y;


    // North For now
    // Draw FSM=================

    // Internal Signal:
    logic [4:0] end_d, dx, dy;
    logic draw_frame, draw_left, draw_right;
    logic first_left, first_right;

    logic signed [CORDW-1:0] x0, y0;  // vertex 0
    logic signed [CORDW-1:0] x1, y1;  // vertex 1
    logic signed [CORDW-1:0] x2, y2;  // vertex 0
    logic signed [CORDW-1:0] x3, y3;  // vertex 1


    // Define a 3-bit enum type
    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        REFRESH   = 3'd1,
        INITLEFT  = 3'd2,
        DRAWLEFT  = 3'd3,
        INITRIGHT = 3'd4,
        DRAWRIGHT = 3'd5
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        case (state)
            REFRESH: begin
                // Draw filled Rec

                // Count end_d
                
                if (map[index_y][px] == 0) begin
                    dy <= dy + 1;
                    end_d <= end_d + 1; 
                end else begin
                    dy <= 0;
                    draw_frame <= 0;
                    state <= INITLEFT;
                end
            end

            INITLEFT: begin
                quad_start <= 1;
                state <= DRAWLEFT;

                if (draw_frame == 0) begin
                    draw_frame <= 1;
                    x0 <= 13'd0;    y0 <= 13'd0;
                    x1 <= W;        y1 <= 13'd0;
                    x2 <= W;        y2 <= H;
                    x3 <= 13'd0;    y3 <= H;
                end else if (first_left == 0) begin
                    first_left <= 1;
                    // Draw the First Block
                    if (map[index_y][px-1] == 0) begin
                        // Left block is empty
                        x0 <= 13'd0;    y0 <= V;
                        x1 <= V;        y1 <= V;
                        x2 <= V;        y2 <= H-V;
                        x3 <= 13'd0;    y3 <= H-V;
                    end else begin
                        // Left block is wall
                        x0 <= 13'd0;    y0 <= 13'd0;
                        x1 <= V;        y1 <= V;
                        x2 <= V;        y2 <= H-V;
                        x3 <= 13'd0;    y3 <= H;
                    end
                end else begin
                    // Draw Regularly

                end
            end

            DRAWLEFT: begin
                quad_start <= 0;
                if (quad_done) begin
                    // Done Drawing
                    if(draw_left == 0) begin
                        state <= INITLEFT;
                        // Check next stage;
                        dy <= dy + 1;
                        // draw_left <= 0;
                    end else begin
                        dy <= 0;
                        state <= INITRIGHT;
                    end
                end
            end
            
            /*
            INITRIHGT: begin
                state <= DRAWLEFT;
                quad_start <= 1;
                if(draw_frame == 0) begin
                    x0 <= 10'd0;    y0 <= 10'd0;
                    x1 <= W;        y1 <= 10'd0;
                    x2 <= W;        y2 <= H;
                    x3 <= 10'd0;    y3 <= H;
                end else begin
                    state <= DRAWRIGHT;
                end
                
            end
            DRAWRIGHT: begin
                quad_start <= 0;
                if (quad_done) begin
                    // Done Drawing
                    if(draw_left == 0) begin
                        if (draw_frame == 0) begin
                            draw_frame <= 1;
                        end else if(dy >= end_d) begin
                            state <= IDLE;
                        end else begin
                            state <= INITLEFT;
                        end
                    end else if (draw_left == 0) begin


                    end else begin
                        state <= INITRIHGT;
                        //if()
                    end
                end
            end
            
            */

            default begin  // IDLE
                state <= IDLE;
            end

            IDLE: begin
                if(refresh) begin
                    state <= REFRESH;
                    end_d <= 0;
                    dx <= 0;
                    dy <= 0;
                    draw_frame <= 0;
                    draw_left <= 0;
                    draw_right <= 0;
                    first_left <= 0;
                    first_right <= 0;
                end
            end

        endcase
    end


    always_comb begin
        index_y <= py-dy;
        V = D[2]; // accesses V
    end

//========================================================
    logic signed [CORDW-1:0] X0, Y0;  // vertex 0
    logic signed [CORDW-1:0] X1, Y1;  // vertex 1
    logic signed [CORDW-1:0] X2, Y2;  // vertex 0
    logic signed [CORDW-1:0] X3, Y3;  // vertex 1

    always_comb begin
        X0 = x0 + displace;
        Y0 = y0 + displace;
        X1 = x1 + displace;
        Y1 = y1 + displace;
        X2 = x2 + displace;
        Y2 = y2 + displace;
        X3 = x3 + displace;
        Y3 = y3 + displace;
    end


    draw_quad #(.CORDW(CORDW))
        u_draw_quad ( 
            .clk(clk),           
            .rst(!rstn),
            .start(quad_start),
            .oe(Write),
            .x0(X0),
            .y0(Y0),   
            .x1(X1),
            .y1(Y1),
            .x2(X2),
            .y2(Y2),
            .x3(X3),
            .y3(Y3),
            .x(draw_X),
            .y(draw_Y),
            .drawing(quad_drawing),
            .busy(quad_busy),
            .done(quad_done)
        );



endmodule
