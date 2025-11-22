// ==========================
    // Drawing module
    // Facing North For now
    
// ============================
module draw_screen #(parameter CORDW=16) (  // signed coordinate width
    input       wire logic clk,             // clock
    input       wire logic rstn,            // reset
    input       wire logic refresh,         // start rectangle drawing

    /*
    input wire logic map;
    input wire logic px;
    input wire logic py;
    input wire logic direction;
    */

    output      logic signed [CORDW-1:0] draw_X,  draw_Y,   // drawing 


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

        displace =  13'd20,
        east    =   2'b00,
        north   =   2'b01,
        west    =   2'b10,
        south   =   2'b11;

    // Parameter array: 1 row, 7 columns
    parameter logic [9:0] Distance [0:6] = '{
        13'd30,    // D0 30
        13'd55,    // D1 25
        13'd78,    // D2 21
        13'd94,    // D3 18
        13'd110,   // D4 16
        13'd124,   // D5 14
        13'd136    // D6 12
        };

    // Player and Map Parameter
    parameter
        row0    =   3'b111,
        row1    =   3'b001,
        row2    =   3'b101,  
        row3    =   3'b001,  
        row4    =   3'b101, 
        row5    =   3'b001, 
        row6    =   3'b101, 

        init_px =   3'd1,
        init_py =   3'd6,
        direction = 2'b01;

    // draw_quad wires================
    logic quad_start;
    logic quad_drawing, quad_busy, quad_done;
    logic Write = 1'b1;

   
    // Change to Input later==============
        // 3 x 5 2D array (x=3, y=5)
        logic [0:2] map [0:6]; // 5 rows, 3 bits each row
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
                map[5] <= row5;
                map[6] <= row6;
            end
        end
    // ===================================


    // Used in the Comb circuit 
    logic [12:0] dV, ddV;
    logic [y_width+1:0] index_x, index_y;
    logic [y_width+1:0] test_x, test_y;
    logic signed [1:0] forward_x, forward_y;
    logic signed [1:0] left_x, left_y;

    // ===================Draw FSM=================

    // Internal Signal:
    logic [4:0] dD, ddD;                  // For Calculating the vertex            
    logic signed [x_width + 1:0] dx, dy;       // For index_x/y
    logic signed [x_width + 1:0] ddx, ddy;     // For test_x/y
    logic [x_width + 1:0] end_d;        // For knowing when to end drawing 

    logic current_block, test_block;

    // Signals for Entering the Right Quad to Draw
    logic isCounting, reachEnd;
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
    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        REFRESH   = 3'd1,
        INITLEFT  = 3'd2,
        DRAWLEFT  = 3'd3,
        INITRIGHT = 3'd4,
        DRAWRIGHT = 3'd5,
        INITEND   = 3'd6,
        DRAWEND   = 3'd7
    } state_t;
    state_t state;

    always_ff @(posedge clk) begin
        case (state)
            REFRESH: begin
                // Draw filled Rec====

                // Count end_d
                if (test_block == 0) begin              // Keep counting when test_block is empty
                    ddx <= ddx + forward_x;             // x Forward
                    ddy <= ddy + forward_y;             // y Forward

                    end_d <= end_d + 1;         // Forward
                end else begin                          // Stop counting when test-block is wall
                    // Proceed to draw left
                    state <= INITLEFT;
                    isCounting <= 1;
                    reachEnd <= 0;
                    
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
                    state <= REFRESH;
                    dx  <= 0;
                    dy  <= 0;
                    ddx <= 0;
                    ddy <= 0;
                    end_d <= 0;

                    reachEnd    <= 0;
                    draw_frame  <= 0;
                    draw_left   <= 0;
                    draw_right  <= 0;
                    draw_end    <= 0;
                    first_left  <= 0;
                    first_right <= 0;
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
            left_x    = 0; left_y      = -1; 
        end else if (direction == north) begin
            forward_x = 0;  forward_y   = -1;
            left_x    = -1; left_y      = 0; 
        end else if (direction == west) begin
            forward_x = -1; forward_y   = 0;
            left_x    = 0;  left_y      = 1; 
        end else if (direction == south) begin
            forward_x = 0;  forward_y   = 1;
            left_x    = 1; left_y      = 0; 
        end

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
