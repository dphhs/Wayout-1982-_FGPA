// ==========================
    // Drawing module
    // Facing North For now
    
// ============================
module draw_screen #(parameter CORDW=16) (  // signed coordinate width
    input       wire logic clk,             // clock
    input       wire logic rstn,            // reset
    input       wire logic refresh,         // start rectangle drawing

    
    // input wire logic map;
    input wire logic signed [5:0] px,
    input wire logic signed [5:0] py,
    input wire logic [1:0] direction,
    

    output      logic signed [CORDW-1:0] draw_X,  draw_Y,   // drawing 
    output      logic [8:0] color,

    // Do these two later if needed
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
);

    // Setting Parameter
    parameter
        H       =   13'd400,
        W       =   13'd400,

        x_width =   5,
        y_width =   5,

        displace =  13'd10,
        east    =   2'b00,
        north   =   2'b01,
        west    =   2'b10,
        south   =   2'b11;

    // Parameter array: 1 row, 7 columns
        parameter logic [12:0] Distance [0:10] = '{
            13'd30,    // D0 30
            13'd55,    // D1 25
            13'd78,    // D2 21
            13'd94,    // D3 18
            13'd110,   // D4 16
            13'd124,   // D5 14
            13'd134,   // D6 10
            13'd143,   // D7 9
            13'd151,   // D8 8
            13'd158,   // D9 7
            13'd164   // D10 6
        };

    // Player and Map Parameter
    parameter
        row0  = 11'b11111111111,
        row1  = 11'b10001000001,
        row2  = 11'b11101110101,
        row3  = 11'b10100010101,
        row4  = 11'b10111011101,
        row5  = 11'b10001000001,
        row6  = 11'b10111101101,
        row7  = 11'b10000000101,
        row8  = 11'b10111011101,
        row9  = 11'b10100010001,
        row10 = 11'b10101000111,
        row11 = 11'b10001010001,
        row12 = 11'b10101111101,
        row13 = 11'b10100010001,
        row14 = 11'b10111010111,
        row15 = 11'b10001000101,
        row16 = 11'b11101111101,
        row17 = 11'b10001000101,
        row18 = 11'b10111010101,
        row19 = 11'b10000010001,
        row20 = 11'b11111111111,
        init_px =   5'd1,
        init_py =   5'd1;
        // direction = 2'b00;

// draw_quad wires================
    logic quad_start;
    logic quad_drawing, quad_busy, quad_done;
    logic signed [CORDW-1:0] quad_draw_X,  quad_draw_Y;
    logic Write = 1'b1;

    // draw_rec wires
    logic rec_start;
    logic rec_drawing, rec_busy, rec_done;
    logic signed [CORDW-1:0] rec_draw_X,  rec_draw_Y;
    logic signed [CORDW-1:0] rec_x0, rec_y0;  // vertex 0
    logic signed [CORDW-1:0] rec_x1, rec_y1;  // vertex 1


    // Change to Input later==============
        // 11 x 21 2D array (x=11, y=21)
        logic [0:10] map [0:20]; // 21 rows, 11 bits each row
        // map[py][px]
        // logic [4:0]px;
        // logic [4:0]py;

        // Initial Map
        always_ff @(posedge clk) begin
            if (!rstn) begin
                //px <= init_px;
                //py <= init_py;
                map[0] <= row0;
                map[1] <= row1;
                map[2] <= row2;
                map[3] <= row3;
                map[4] <= row4;
                map[5] <= row5;
                map[6] <= row6;
                map[7] <= row7;
                map[8] <= row8;
                map[9] <= row9;
                map[10] <= row10;
                map[11] <= row11;
                map[12] <= row12;
                map[13] <= row13;
                map[14] <= row14;
                map[15] <= row15;
                map[16] <= row16;
                map[17] <= row17;
                map[18] <= row18;
                map[19] <= row19;
                map[20] <= row20;
            end
        end
    // ===================================


// Used in the Comb circuit 
    logic [12:0] dV, ddV;
    logic signed [5:0] index_x, index_y;
    logic signed [5:0] test_x, test_y;
    logic signed [5:0] forward_x, forward_y;
    logic signed [5:0] left_x, left_y;

// ===================Draw FSM=================

    // Internal Signal:
    logic signed [5:0] dD, ddD;                  // For Calculating the vertex            
    logic signed [5:0] dx, dy;       // For index_x/y
    logic signed [5:0] ddx, ddy;     // For test_x/y
    logic [5:0] end_d;        // For knowing when to end drawing 

    logic current_block, test_block;

// Signals for Entering the Right Quad to Draw
    // Signal for Refresh
    logic draw_clear, draw_map;
    logic [5:0] x_count, y_count;
    parameter block_width = 13'd20;

    // Signal for INIT
    logic isCounting, reachEnd;
    // Signal for LEFT and RIGHT
    logic draw_frame, draw_left, draw_right, draw_end;
    logic first_left, first_right;


// Vertexes
    logic signed [CORDW-1:0] x0, y0;  // vertex 0
    logic signed [CORDW-1:0] x1, y1;  // vertex 1
    logic signed [CORDW-1:0] x2, y2;  // vertex 0
    logic signed [CORDW-1:0] x3, y3;  // vertex 1

    // End Vertexes
    logic signed [CORDW-1:0] end_x0, end_y0;  // End vertex 0
    logic signed [CORDW-1:0] end_x1, end_y1;  // End vertex 1
    logic signed [CORDW-1:0] end_x2, end_y2;  // End vertex 2
    logic signed [CORDW-1:0] end_x3, end_y3;  // End vertex 3

// Define a 3-bit enum type
    typedef enum logic [3:0] {
        IDLE        = 4'd0,
        INITREFRESH = 4'd1,
        DRAWREFRESH = 4'd2,
        INIT        = 4'd3,
        INITLEFT    = 4'd4,
        DRAWLEFT    = 4'd5,
        INITRIGHT   = 4'd6,
        DRAWRIGHT   = 4'd7,
        INITEND     = 4'd8,
        DRAWEND     = 4'd9
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        case (state)
            INITREFRESH: begin
                if (draw_clear == 0) begin
                    rec_start <= 1;
                    state <= DRAWREFRESH;
                    draw_clear <= 1;

                    color <= 9'b000011011;
                    rec_x0 <= 13'd0;    rec_y0 <= 13'd0;
                    rec_x1 <= 13'd640;  rec_y1 <= 13'd480;
                end else begin
                    if(x_count < 10) begin
                        x_count <= x_count + 1;
                        if(y_count == 21) begin
                            draw_map <= 1;
                            state <= INIT;
                            color <= 9'b111111111;
                        end else begin
                            draw_map <= 0;
                            rec_start <= 1;
                            state <= DRAWREFRESH;
                        end
                    end else begin
                        x_count <= 0;
                        y_count <= y_count + 1;
                    end
                if(map[y_count][x_count] == 1) begin
                    color <= 9'b111111111;
                end else begin
                    color <= 9'b000011011;
                end
                rec_x0 <= x_count * 13'd20 + 13'd410;   
                rec_x1 <= x_count * 13'd20 + 13'd410 + 13'd20;           
                rec_y0 <= y_count * 13'd20 + 13'd30; 
                rec_y1 <= y_count * 13'd20 + 13'd30 + 13'd20; 
                end
            end

            DRAWREFRESH: begin
                rec_start <= 0;
                if (rec_done) begin
                    if (draw_map == 0) begin
                        state <= INITREFRESH;
                        color <= 9'b111111111;
                    end else begin
                        state <= INIT;
                        color <= 9'b111111111;

                    end
                end
            end

            INIT: begin
                // Count end_d
                if (test_block == 0) begin              // Keep counting when test_block is empty
                    ddx <= ddx + forward_x;             // x Forward
                    ddy <= ddy + forward_y;             // y Forward

                    end_d <= end_d + 1;         // Forward
                end else begin                          // Stop counting when test-block is wall
                    // Proceed to draw left
                    state <= INITLEFT;
                    
                    isCounting <= 1;
                    
                    color <= 9'b111111111;
                    dD   <= 0;
                    ddD  <= 0;
                    dx  <= left_x;             // Left
                    dy  <= left_y;             // Stay
                    ddx <= left_x;             // Left
                    ddy <= left_y;             // Stay
                end
            end

            INITLEFT: begin
                // Count until the wall type change
                if (isCounting) begin                   // Keep counting
                    if (ddD == end_d) begin    // Stop Counting when reaches the end
                        reachEnd <= 1;
                        draw_left <= 1;
                        isCounting <= 0;
                        // In the case it just go straight to the end:
                        if (first_left == 0) begin
                            draw_left <= 1;
                            if (current_block == 0) begin       // Left block is empty
                                // Prevent Drawing Left empty block;
                                state <= DRAWLEFT;
                                quad_start <= 1;
                                first_left <= 1;

                                x0 <= 13'd0;    y0 <= 13'd0;
                                x1 <= 13'd0;    y1 <= 13'd0;
                                x2 <= 13'd0;    y2 <= 13'd0;
                                x3 <= 13'd0;    y3 <= 13'd0;
                                // Load the left end block vertex directly
                                end_x0 <= 13'd0;    end_y0 <= ddV; 
                                end_x3 <= 13'd0;    end_y3 <= (H-ddV);
                            end else begin                      // Left block is Wall
                                end_x0 <= ddV;  end_y0 <= ddV; 
                                end_x3 <= ddV;  end_y3 <= (H-ddV); 
                            end
                        end
                    end else if (test_block == current_block) begin // Keep counting until test_block is a different block
                        ddx <= ddx + forward_x;             // x Forward
                        ddy <= ddy + forward_y;             // y Forward
                        ddD <= ddD + 1;             // Distance Increment 1;
                    end else begin  // Stop Counting when type change
                        isCounting <= 0;
                    end 
                end else if (first_left == 0) begin
                    // Draw the First Block
                    // Send to Draw State
                        state <= DRAWLEFT;
                        quad_start <= 1;
                        first_left <= 1;
                    // Send Vertex
                    if (current_block == 0) begin       // Left block is empty
                        x0 <= 13'd0;    y0 <= ddV;
                        x1 <= ddV;      y1 <= ddV;
                        x2 <= ddV;      y2 <= (H-ddV);
                        x3 <= 13'd0;    y3 <= (H-ddV);
                    end else begin                      // Left block is wall
                        x0 <= 13'd0;    y0 <= 13'd0;
                        x1 <= ddV;      y1 <= ddV;
                        x2 <= ddV;      y2 <= H-ddV;
                        x3 <= 13'd0;    y3 <= H;
                    end
                end else begin
                    // Draw Regularly
                    state <= DRAWLEFT;
                    quad_start <= 1;
                    if (current_block == 0) begin       // Left block is empty
            
                        if (!reachEnd) begin            // Only draw if not reach end
                            x0 <= dV;       y0 <= ddV;
                            x1 <= ddV;      y1 <= ddV;
                            x2 <= ddV;      y2 <= (H-ddV);
                            x3 <= dV;       y3 <= (H-ddV);
                        end else begin
                            // Reaches the end, store the left vertex of the end block
                            end_x0 <= dV;    end_y0 <= ddV; 
                            end_x3 <= dV;    end_y3 <= (H-ddV);
                        end
                    end else begin                      // Left block is wall
                        // Draw Regardless if reach end
                        x0 <= dV;       y0 <= dV;
                        x1 <= ddV;      y1 <= ddV;
                        x2 <= ddV;      y2 <= (H-ddV);
                        x3 <= dV;       y3 <= (H-dV);
                        if (reachEnd) begin
                            // store the left vertex of the end block
                            end_x0 <= ddV;  end_y0 <= ddV; 
                            end_x3 <= ddV;  end_y3 <= (H-ddV); 
                        end
                    end
                end
            end

            DRAWLEFT: begin
                quad_start <= 0;
                if (quad_done) begin
                    // Done Drawing
                    if(draw_left == 0) begin
                        // Draw the next object on left
                        state <= INITLEFT;
                        isCounting <= 1;
                        // Now current_block move to where we stopped the test_block 
                        dx <= ddx;                 
                        dy <= ddy;
                        dD <= ddD;                 

                    // Done, drawing Left == 1
                    end else begin
                        // Proceed to draw right
                        state <= INITRIGHT;
                        isCounting <= 1;
                        reachEnd <= 0;

                        dD <= 0;
                        ddD <= 0;
                        dx  <= -left_x;              // Right
                        dy  <= -left_y;              // Stay
                        ddx <= -left_x;              // Right
                        ddy <= -left_y;              // Stay
                    end
                end
            end

            
            INITRIGHT: begin
                // Count until the wall type change
                if (isCounting) begin           
                     if (ddD == end_d) begin    // Stop Counting when reaches the end
                        reachEnd <= 1;
                        draw_right <= 1;
                        isCounting <= 0;
                        // In the case it just go straight to the end:
                        if (first_right == 0) begin
                            draw_right <= 1;
                            if (current_block == 0) begin       // Left block is empty
                            // Prevent Drawing Right empty block;
                                state <= DRAWRIGHT;
                                quad_start <= 1;
                                first_right <= 1;
                                

                                x0 <= 13'd0;    y0 <= 13'd0;
                                x1 <= 13'd0;    y1 <= 13'd0;
                                x2 <= 13'd0;    y2 <= 13'd0;
                                x3 <= 13'd0;    y3 <= 13'd0;
                                // Load the left end block vertex directly
                                end_x1 <= W;        end_y1 <= ddV; 
                                end_x2 <= W;        end_y2 <= (H-ddV);

                            end else begin
                                end_x1 <= W-ddV;    end_y1 <= ddV; 
                                end_x2 <= W-ddV;    end_y2 <= (H-ddV);
                            end
                        end
                     end else if (test_block == current_block) begin // Or stop counting when test_block is a different block
                        ddx <= ddx + forward_x;             // x Forward
                        ddy <= ddy + forward_y;             // y Forward
                        ddD <= ddD + 1;             // Distance Increment 1;
                    end else begin    // Stop Counting when type change
                        isCounting <= 0;
                    end 
                end else if (first_right == 0) begin
                    // Draw the First Block
                    // Send to Draw State
                    state <= DRAWRIGHT;
                    quad_start <= 1;
                    first_right <= 1;
                    if (current_block == 0) begin
                        // Right block is empty
                        x0 <= W;            y0 <= ddV;
                        x1 <= W;            y1 <= H-ddV;
                        x2 <= W-ddV;        y2 <= H-ddV;
                        x3 <= W-ddV;        y3 <= ddV;
                    end else begin
                        // Right block is wall
                        x0 <= W;            y0 <= 13'd0;
                        x1 <= W;            y1 <= H;
                        x2 <= W-ddV;        y2 <= H-ddV;
                        x3 <= W-ddV;        y3 <= ddV;
                    end
                end else begin
                    // Draw Regularly
                    state <= DRAWRIGHT;
                    quad_start <= 1;
                    if (current_block == 0) begin       // Right block is empty
                        if (!reachEnd) begin            // Only draw if not reach end
                            x0 <= W-dV;      y0 <= ddV;
                            x1 <= W-dV;      y1 <= H-ddV;
                            x2 <= W-ddV;     y2 <= H-ddV;
                            x3 <= W-ddV;     y3 <= ddV;
                        end else begin
                            // Reaches the end, store the right vertex of the end block
                            end_x1 <= W-dV;    end_y1 <= ddV; 
                            end_x2 <= W-dV;    end_y2 <= (H-ddV);
                        end
                    end else begin                      // right block is wall
                        // Draw Regardless if reach_end
                        x0 <= W-dV;         y0 <= dV;
                        x1 <= W-dV;         y1 <= H-dV;
                        x2 <= W-ddV;        y2 <= H-ddV;
                        x3 <= W-ddV;        y3 <= ddV;
                        if (reachEnd) begin
                            // store the right vertex of the end block
                            end_x1 <= W-ddV;    end_y1 <= ddV; 
                            end_x2 <= W-ddV;    end_y2 <= (H-ddV);
                        end
                    end
                end
            end

            DRAWRIGHT: begin
                quad_start <= 0;
                if (quad_done) begin
                    // Done Drawing
                    if (draw_right == 0) begin
                        // Draw the next object on right
                        state <= INITRIGHT;
                        isCounting <= 1;
                        // Now current_block move to where we stopped the test_block 
                        dx <= ddx;                 
                        dy <= ddy;
                        dD <= ddD; 
                    // Done drawing Right
                    end else begin
                        // Proceed to draw final quad, frame quad and end quad
                        state <= INITEND;
                    end
                end
            end
            
            INITEND: begin
                quad_start <= 1;
                state <= DRAWEND;
                if (draw_frame == 0) begin
                    draw_frame <= 1;
                    x0 <= 13'd0;    y0 <= 13'd0;
                    x1 <= W;        y1 <= 13'd0;
                    x2 <= W;        y2 <= H;
                    x3 <= 13'd0;    y3 <= H;
                end else begin
                    // For Testing now, change this to end block==========
                    draw_end <= 1;
                    x0 <= end_x0;    y0 <= end_y0;
                    x1 <= end_x1;    y1 <= end_y1;
                    x2 <= end_x2;    y2 <= end_y2;
                    x3 <= end_x3;    y3 <= end_y3;
                end
            end 

            DRAWEND: begin
                quad_start <= 0;
                if (quad_done) begin
                    if (draw_end == 0) begin
                        state <= INITEND;
                    end else begin
                        state <= IDLE;
                    end
                end
            end



            IDLE: begin
                if(refresh) begin
                    state <= INITREFRESH;
                    dx  <= 0;
                    dy  <= 0;
                    ddx <= 0;
                    ddy <= 0;
                    end_d <= 0;

                    draw_clear  <= 0;
                    draw_map    <= 0;
                    x_count     <= 0;
                    y_count     <= 0;

                    reachEnd    <= 0;
                    draw_left   <= 0;
                    draw_right  <= 0;
                    draw_end    <= 0;
                    first_left  <= 0;
                    first_right <= 0;
                    draw_frame  <= 0;
                end
            end

            default begin  // IDLE
                state <= IDLE;
            end
        endcase
    end



    always_comb begin
        index_x = px + dx;
        index_y = py + dy;
        current_block = map[index_y][index_x];

        test_x = px + ddx;
        test_y = py + ddy;  
        test_block = map[test_y][test_x];

        dV           = Distance[dD-1];    // accesses V
        ddV          = Distance[ddD-1];

        if (direction == east) begin
            forward_x = 1;  forward_y   = 0;
            left_x    = 0;  left_y      = -1; 
        end else if (direction == north) begin
            forward_x = 0;  forward_y   = -1;
            left_x    = -1; left_y      = 0; 
        end else if (direction == west) begin
            forward_x = -1; forward_y   = 0;
            left_x    = 0;  left_y      = 1; 
        end else if (direction == south) begin
            forward_x = 0;  forward_y   = 1;
            left_x    = 1;  left_y      = 0; 
        end else begin
            forward_x = 0;  forward_y   = 0;
            left_x    = 0;  left_y      = 0;
        end
    end

    


    always_comb begin
        if (quad_drawing) begin
            draw_X = quad_draw_X;
            draw_Y = quad_draw_Y;
            // color = 9'b111111111;
        end else begin
            draw_X = rec_draw_X;
            draw_Y = rec_draw_Y;
            // color = 9'b000000111;
        end
    end



//========================================================
    logic signed [CORDW-1:0] X0, Y0;  // vertex 0
    logic signed [CORDW-1:0] X1, Y1;  // vertex 1
    logic signed [CORDW-1:0] X2, Y2;  // vertex 0
    logic signed [CORDW-1:0] X3, Y3;  // vertex 1

    parameter rec_displace_x = 13'd420;
    parameter rec_displace_y = 13'd30;
    logic signed [CORDW-1:0] rec_X0, rec_Y0;  // vertex 0
    logic signed [CORDW-1:0] rec_X1, rec_Y1;  // vertex 1

    always_comb begin
        X0 = x0 + displace;
        Y0 = y0 + displace;
        X1 = x1 + displace;
        Y1 = y1 + displace;
        X2 = x2 + displace;
        Y2 = y2 + displace;
        X3 = x3 + displace;
        Y3 = y3 + displace;
        /*
        if(draw_clear) begin
            rec_X0 = rec_x0 + rec_displace_x;
            rec_X1 = rec_x1 + rec_displace_x;
            rec_Y0 = rec_y0 + rec_displace_y;
            rec_Y1 = rec_y1 + rec_displace_y;
        end else begin
            rec_X0 = rec_x0;
            rec_X1 = rec_x1;
            rec_Y0 = rec_y0;
            rec_Y1 = rec_y1;
        end 
        */
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
            .x(quad_draw_X),
            .y(quad_draw_Y),
            .drawing(quad_drawing),
            .busy(quad_busy),
            .done(quad_done)
        );




        draw_rectangle_fill #(.CORDW(CORDW))
            u_draw_rectangle_fill ( 
            .clk(clk),           
            .rst(!rstn),
            .start(rec_start),
            .oe(Write),
            .x0(rec_X0),
            .y0(rec_Y0),   
            .x1(rec_X1),
            .y1(rec_Y1),
            .x(rec_draw_X),
            .y(rec_draw_Y),
            .drawing(rec_drawing),
            .busy(rec_busy),
            .done(rec_done)
        );



endmodule
