
    // State machine
    localparam IDLEE = 0, 
            READ_X0 = 1, READ_Y0 = 2,
            READ_X1 = 3, READ_Y1 = 4,
            READ_X2 = 5, READ_Y2 = 6,
            READ_X3 = 7, READ_Y3 = 8,
            START_DRAW = 9, DRAWING = 10;
    reg [3:0] state;

    // Read coordinates for drawing
    always @(posedge CLOCK_50) begin
        if (Resetn == 0) begin
            state <= IDLEE;
            draw_lines <= 0;
        end else begin
            case (state)
                IDLEE: begin
                    draw_lines <= 0;
                    if (start_loading) begin  // Some trigger signal
                        read_addr <= {current_line, 3'd0};  // Load X0
                        state <= READ_X0;
                    end
                end
                READ_X0: begin
                    x0 <= read_data;
                    read_addr <= {current_line, 3'd1};  // Load X0
                    state <= READ_Y0;
                end
                
                READ_Y0: begin
                    y0 <= read_data;
                    read_addr <= {current_line, 3'd2};  // Load X0
                    state <= READ_X1;
                end
                
                READ_X1: begin
                    x1 <= read_data;
                    read_addr <= {current_line, 3'd3};  // Load X0
                    state <= READ_Y1;
                end
                
                READ_Y1: begin
                    y1 <= read_data;
                    read_addr <= {current_line, 3'd4};  // Load X0
                    state <= READ_X2;
                end
                
                READ_X2: begin
                    x2 <= read_data;
                    read_addr <= {current_line, 3'd5};  // Load X0
                    state <= READ_Y2;
                end
                
                READ_Y2: begin
                    y2 <= read_data;
                    read_addr <= {current_line, 3'd6};  // Load X0
                    state <= READ_X3;
                end
                
                READ_X3: begin
                    x3 <= read_data;
                    read_addr <= {current_line, 3'd7};  // Load X0
                    state <= READ_Y3;
                end
                
                READ_Y3: begin
                    y3 <= read_data;
                    state <= START_DRAW;
                end
                
                START_DRAW: begin
                    draw_lines <= 1;  // Signal to start drawing
                    state <= DRAWING;
                end
                
                DRAWING: begin
                    if (line_done) begin  // Wait for drawing to complete
                        draw_lines <= 0;
                        state <= IDLEE;
                    end
                end
                
                default: begin
                    state <= IDLEE;
                    draw_lines <= 0;
                end
            endcase
        end
    end
