
    // draw state machine
    enum {IDLE, INIT, DRAW} state;
    always_ff @(posedge clk) begin
        case (state)
            INIT: begin  // register coordinates
                state <= DRAW;
                line_start <= 1;
                if (line_id == 2'd0) begin  // (x0,y0) (x1,y1)
                    lx0 <= x0; ly0 <= y0;
                    lx1 <= x1; ly1 <= y1;
                end else if (line_id == 2'd1) begin  // (x1,y1) (x2,y2)
                    lx0 <= x1; ly0 <= y1;
                    lx1 <= x2; ly1 <= y2;
                end else begin  // (x2,y2) (x0,y0)
                    lx0 <= x2; ly0 <= y2;
                    lx1 <= x0; ly1 <= y0;
                end
            end
            DRAW: begin
                line_start <= 0;
                if (line_done) begin
                    if (line_id == 2) begin  // final line
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
                    line_id <= 0;
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


    