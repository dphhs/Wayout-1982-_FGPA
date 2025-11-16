module vertex_loader (
    input wire clk,
    input wire rst_n,           // Active low reset
    input wire start_loading,   // Trigger to load vertices
    input wire line_done,       // Signal when drawing is complete
    input wire [2:0] shape_sel, // Which shape to load (0-7)
    
    // Output vertex coordinates
    output reg [9:0] x0, y0, x1, y1, x2, y2, x3, y3,
    output reg draw_lines      // High when ready to draw
);

    // RAM signals
    reg [5:0] read_addr, write_addr;
    reg [9:0] write_data;
    reg write_enable;
    wire [9:0] read_data;

    reg busy, ready;

    // Instantiate the RAM
    vertex_ram u_vertex_ram (
        .clock(clk),
        .data(write_data),
        .rdaddress(read_addr),
        .wraddress(write_addr),
        .wren(write_enable),
        .q(read_data)
    );

    // Current shape being loaded
    reg [2:0] current_shape;

    // State machine
    localparam IDLE = 0, 
               READ_X0 = 1, READ_Y0 = 2,
               READ_X1 = 3, READ_Y1 = 4,
               READ_X2 = 5, READ_Y2 = 6,
               READ_X3 = 7, READ_Y3 = 8,
               START_DRAW = 9, DRAWING = 10, WAIT = 11;
    
    reg [3:0] state;

    // Read coordinates from RAM
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            draw_lines <= 0;
            busy <= 0;
            ready <= 0;
            current_shape <= 0;
            x0 <= 0; y0 <= 0;
            x1 <= 0; y1 <= 0;
            x2 <= 0; y2 <= 0;
            x3 <= 0; y3 <= 0;
            read_addr <= 0;
            write_enable <= 0;
        end else begin
            // Default: no writing
            write_enable <= 0;
            
            case (state)
                IDLE: begin
                    draw_lines <= 0;
                    busy <= 0;
                    ready <= 0;
                    
                    if (start_loading) begin
                        current_shape <= shape_sel;
                        read_addr <= {shape_sel, 3'd0};  // Address for x0
                        state <= READ_X0;
                        busy <= 1;
                    end
                end
                
                READ_X0: begin
                    x0 <= read_data;
                    read_addr <= {current_shape, 3'd1};  // Address for y0
                    state <= WAIT;
                end
                WAIT: begin
                    read_addr <= {current_shape, 3'd2};  // Address for x1
                    state <= READ_Y0;
                end
                
                READ_Y0: begin
                    y0 <= read_data;
                    read_addr <= {current_shape, 3'd3};  // Address for y1
                    state <= READ_X1;
                end
                
                READ_X1: begin
                    x1 <= read_data;
                    read_addr <= {current_shape, 3'd4};  // Address for x2
                    state <= READ_Y1;
                end
                
                READ_Y1: begin
                    y1 <= read_data;
                    read_addr <= {current_shape, 3'd5};  // Address for y2
                    state <= READ_X2;
                end
                
                READ_X2: begin
                    x2 <= read_data;
                    read_addr <= {current_shape, 3'd6};  // Address for x3
                    state <= READ_Y2;
                end
                
                READ_Y2: begin
                    y2 <= read_data;
                    read_addr <= {current_shape, 3'd7};  // Address for y3
                    state <= READ_X3;
                end
                
                READ_X3: begin
                    x3 <= read_data;
                    read_addr <= {current_shape, 3'd7};  // Address for y3
                    state <= READ_Y3;
                end
                
                READ_Y3: begin
                    y3 <= read_data;
                    state <= START_DRAW;
                end
                
                START_DRAW: begin
                    draw_lines <= 1;  // Signal to start drawing
                    ready <= 1;       // Vertices are ready
                    busy <= 0;        // Loading complete
                    state <= DRAWING;
                end
                
                DRAWING: begin
                    if (line_done) begin  // Wait for drawing to complete
                        draw_lines <= 0;
                        ready <= 0;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                    draw_lines <= 0;
                    busy <= 0;
                    ready <= 0;
                end
            endcase
        end
    end

endmodule